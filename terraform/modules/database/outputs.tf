output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_name" {
  description = "Name of the RDS database"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Username for the RDS database"
  value       = aws_db_instance.main.username
}

output "db_password_secret_arn" {
  description = "ARN of the secret containing the database password"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "redis_endpoint" {
  description = "Endpoint of the Redis cluster"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Reader endpoint of the Redis cluster"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "dynamodb_table_user_data_arn" {
  description = "ARN of the user data DynamoDB table"
  value       = aws_dynamodb_table.user_data.arn
}

output "dynamodb_table_metrics_arn" {
  description = "ARN of the metrics DynamoDB table"
  value       = aws_dynamodb_table.metrics.arn
}

output "dynamodb_table_request_logs_arn" {
  description = "ARN of the request logs DynamoDB table"
  value       = aws_dynamodb_table.request_logs.arn
}

output "dax_cluster_endpoint" {
  description = "Endpoint of the DAX cluster"
  value       = var.environment == "prod" && length(aws_dax_cluster.main) > 0 ? aws_dax_cluster.main[0].cluster_discovery_endpoint : null
}
