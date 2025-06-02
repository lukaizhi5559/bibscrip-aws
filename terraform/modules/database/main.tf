# Random password for RDS
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project_name}-${var.environment}-db-password"
  description = "Password for ${var.project_name} ${var.environment} database"
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-db-password"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-pg-param-group"
  family = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "pg_stat_statements.track"
    value = "ALL"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-pg-param-group"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-${var.environment}-db"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = var.db_max_allocated_storage
  storage_type           = "gp3"
  storage_encrypted      = true
  username               = var.db_username
  password               = random_password.db_password.result
  db_name                = var.db_name
  multi_az               = var.environment == "prod" ? true : false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name
  skip_final_snapshot    = var.environment == "prod" ? false : true
  deletion_protection    = var.environment == "prod" ? true : false
  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:30-sun:05:30"
  auto_minor_version_upgrade = true
  publicly_accessible    = false
  apply_immediately      = var.environment == "prod" ? false : true
  monitoring_interval    = 60
  monitoring_role_arn    = aws_iam_role.rds_monitoring.arn
  copy_tags_to_snapshot  = true
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }

  lifecycle {
    prevent_destroy = var.environment == "prod" ? true : false
  }
}

# RDS Enhanced Monitoring Role
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-cache-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-cache-subnet-group"
  }
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-redis-param-group"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-param-group"
  }
}

# ElastiCache Replication Group
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.project_name}-${var.environment}-redis"
  description                = "${var.project_name} ${var.environment} Redis cluster"
  node_type                  = var.redis_node_type
  port                       = 6379
  parameter_group_name       = aws_elasticache_parameter_group.main.name
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [var.elasticache_security_group_id]
  automatic_failover_enabled = var.environment == "prod" ? true : false
  multi_az_enabled           = var.environment == "prod" ? true : false
  num_cache_clusters         = var.redis_num_cache_nodes
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auto_minor_version_upgrade = true
  maintenance_window         = "sun:05:00-sun:06:00"
  snapshot_retention_limit   = var.environment == "prod" ? 7 : 1
  snapshot_window            = "00:00-01:00"
  engine_version             = "7.0"

  tags = {
    Name = "${var.project_name}-${var.environment}-redis"
  }
}

# DynamoDB Tables
resource "aws_dynamodb_table" "user_data" {
  name         = "${var.project_name}-${var.environment}-user-data"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "userId"
  
  attribute {
    name = "userId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }

  server_side_encryption {
    enabled = true
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-user-data"
  }
}

resource "aws_dynamodb_table" "metrics" {
  name         = "${var.project_name}-${var.environment}-metrics"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "id"
  range_key    = "timestamp"
  
  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }

  server_side_encryption {
    enabled = true
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-metrics"
  }
}

resource "aws_dynamodb_table" "request_logs" {
  name         = "${var.project_name}-${var.environment}-request-logs"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "requestId"
  
  attribute {
    name = "requestId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  global_secondary_index {
    name               = "UserIdIndex"
    hash_key           = "userId"
    range_key          = "timestamp"
    projection_type    = "ALL"
  }

  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }

  server_side_encryption {
    enabled = true
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-request-logs"
  }
}

# DynamoDB Accelerator (DAX) for frequently accessed items
resource "aws_dax_cluster" "main" {
  count                  = var.environment == "prod" ? 1 : 0
  cluster_name           = "${var.project_name}-${var.environment}-dax"
  iam_role_arn           = aws_iam_role.dax.arn
  node_type              = "dax.t3.small"
  replication_factor     = 2
  subnet_group_name      = aws_dax_subnet_group.main.name
  security_group_ids     = [var.elasticache_security_group_id] # Reusing the ElastiCache security group
  availability_zones     = var.availability_zones
  server_side_encryption = true

  tags = {
    Name = "${var.project_name}-${var.environment}-dax"
  }
}

# DAX Subnet Group
resource "aws_dax_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-dax-subnet-group"
  subnet_ids = var.private_subnet_ids
}

# DAX IAM Role
resource "aws_iam_role" "dax" {
  name = "${var.project_name}-${var.environment}-dax-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dax.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-dax-role"
  }
}

resource "aws_iam_role_policy" "dax" {
  name = "${var.project_name}-${var.environment}-dax-policy"
  role = aws_iam_role.dax.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
