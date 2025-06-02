# CloudWatch Dashboard for the application
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${var.alb_arn_suffix}", { "stat": "Sum", "period": 300 }],
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${var.alb_arn_suffix}", { "stat": "Average", "period": 300 }]
        ],
        "region": "${var.aws_region}",
        "title": "ALB Request Count and Response Time",
        "view": "timeSeries",
        "stacked": false
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/CloudFront", "Requests", "DistributionId", "${var.cloudfront_distribution_id}", { "stat": "Sum", "period": 300 }],
          ["AWS/CloudFront", "BytesDownloaded", "DistributionId", "${var.cloudfront_distribution_id}", { "stat": "Sum", "period": 300 }]
        ],
        "region": "us-east-1",
        "title": "CloudFront Requests and Bytes Downloaded",
        "view": "timeSeries",
        "stacked": false
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.ecs_service_name}", "ClusterName", "${var.ecs_cluster_name}", { "stat": "Average", "period": 300 }],
          ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.ecs_service_name}", "ClusterName", "${var.ecs_cluster_name}", { "stat": "Average", "period": 300 }]
        ],
        "region": "${var.aws_region}",
        "title": "ECS CPU and Memory Utilization",
        "view": "timeSeries",
        "stacked": false
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.rds_instance_id}", { "stat": "Average", "period": 300 }],
          ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${var.rds_instance_id}", { "stat": "Average", "period": 300 }],
          ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${var.rds_instance_id}", { "stat": "Average", "period": 300 }]
        ],
        "region": "${var.aws_region}",
        "title": "RDS CPU, Connections, and Storage",
        "view": "timeSeries",
        "stacked": false
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 12,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", "${var.elasticache_cluster_id}", { "stat": "Average", "period": 300 }],
          ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", "${var.elasticache_cluster_id}", { "stat": "Average", "period": 300 }],
          ["AWS/ElastiCache", "CurrConnections", "CacheClusterId", "${var.elasticache_cluster_id}", { "stat": "Average", "period": 300 }]
        ],
        "region": "${var.aws_region}",
        "title": "ElastiCache CPU, Memory, and Connections",
        "view": "timeSeries",
        "stacked": false
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 12,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "${var.dynamodb_user_table}", { "stat": "Sum", "period": 300 }],
          ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", "${var.dynamodb_user_table}", { "stat": "Sum", "period": 300 }]
        ],
        "region": "${var.aws_region}",
        "title": "DynamoDB Read/Write Capacity",
        "view": "timeSeries",
        "stacked": false
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 18,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/Lambda", "Invocations", "FunctionName", "${var.lambda_function_name}", { "stat": "Sum", "period": 300 }],
          ["AWS/Lambda", "Duration", "FunctionName", "${var.lambda_function_name}", { "stat": "Average", "period": 300 }],
          ["AWS/Lambda", "Errors", "FunctionName", "${var.lambda_function_name}", { "stat": "Sum", "period": 300 }]
        ],
        "region": "${var.aws_region}",
        "title": "Lambda Invocations, Duration, and Errors",
        "view": "timeSeries",
        "stacked": false
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 18,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/SQS", "NumberOfMessagesSent", "QueueName", "${var.request_queue_name}", { "stat": "Sum", "period": 300 }],
          ["AWS/SQS", "NumberOfMessagesReceived", "QueueName", "${var.request_queue_name}", { "stat": "Sum", "period": 300 }],
          ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "${var.request_queue_name}", { "stat": "Average", "period": 300 }]
        ],
        "region": "${var.aws_region}",
        "title": "SQS Queue Metrics",
        "view": "timeSeries",
        "stacked": false
      }
    }
  ]
}
EOF

  depends_on = [
    var.alb_arn_suffix,
    var.cloudfront_distribution_id,
    var.ecs_service_name,
    var.ecs_cluster_name,
    var.rds_instance_id,
    var.elasticache_cluster_id,
    var.dynamodb_user_table,
    var.lambda_function_name,
    var.request_queue_name
  ]
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.environment == "prod" ? 10 : 50
  alarm_description   = "This alarm monitors API 5XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.project_name}-${var.environment}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = var.environment == "prod" ? 1 : 3
  alarm_description   = "This alarm monitors API latency"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10000000000  # 10 GB
  alarm_description   = "This alarm monitors RDS free storage space"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-elasticache-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors ElastiCache CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    CacheClusterId = var.elasticache_cluster_id
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttling" {
  alarm_name          = "${var.project_name}-${var.environment}-dynamodb-throttling"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.environment == "prod" ? 10 : 50
  alarm_description   = "This alarm monitors DynamoDB throttled requests"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    TableName = var.dynamodb_user_table
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.environment == "prod" ? 5 : 20
  alarm_description   = "This alarm monitors Lambda function errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    FunctionName = var.lambda_function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth" {
  alarm_name          = "${var.project_name}-${var.environment}-sqs-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "This alarm monitors SQS queue depth"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    QueueName = var.request_queue_name
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-alerts"
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# AWS X-Ray
resource "aws_xray_sampling_rule" "api_tracing" {
  rule_name      = "${var.project_name}-${var.environment}-api-tracing"
  priority       = 1
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.05
  url_path       = "/api/*"
  host           = "*"
  http_method    = "*"
  service_name   = "*"
  service_type   = "*"
  
  attributes = {
    Environment = var.environment
  }
}

# CloudWatch Synthetics for API and frontend availability monitoring
resource "aws_synthetics_canary" "api_health" {
  name                 = "${var.project_name}-${var.environment}-api-health"
  artifact_s3_location = "s3://${var.s3_canary_bucket}/${var.project_name}/${var.environment}/api-health/"
  execution_role_arn   = aws_iam_role.canary.arn
  handler              = "apiCanary.handler"
  runtime_version      = "syn-nodejs-puppeteer-6.1"
  start_canary         = true
  
  schedule {
    expression = "rate(5 minutes)"
  }
  
  code {
    handler  = "apiCanary.handler"
    s3_bucket = var.s3_canary_bucket
    s3_key    = "${var.project_name}/${var.environment}/canary/api-health.zip"
  }

  run_config {
    timeout_in_seconds = 60
    memory_in_mb       = 1024
    active_tracing     = true
  }

  success_retention_period = 3
  failure_retention_period = 14
  
  tags = {
    Name = "${var.project_name}-${var.environment}-api-health"
  }
}

resource "aws_synthetics_canary" "frontend_health" {
  name                 = "${var.project_name}-${var.environment}-frontend-health"
  artifact_s3_location = "s3://${var.s3_canary_bucket}/${var.project_name}/${var.environment}/frontend-health/"
  execution_role_arn   = aws_iam_role.canary.arn
  handler              = "frontendCanary.handler"
  runtime_version      = "syn-nodejs-puppeteer-6.1"
  start_canary         = true
  
  schedule {
    expression = "rate(5 minutes)"
  }
  
  code {
    handler  = "frontendCanary.handler"
    s3_bucket = var.s3_canary_bucket
    s3_key    = "${var.project_name}/${var.environment}/canary/frontend-health.zip"
  }

  run_config {
    timeout_in_seconds = 60
    memory_in_mb       = 1024
    active_tracing     = true
  }

  success_retention_period = 3
  failure_retention_period = 14
  
  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-health"
  }
}

# S3 bucket for canary artifacts
resource "aws_s3_bucket" "canary" {
  bucket = var.s3_canary_bucket
  
  tags = {
    Name = "${var.project_name}-${var.environment}-canary-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "canary" {
  bucket = aws_s3_bucket.canary.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "canary" {
  bucket = aws_s3_bucket.canary.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.canary]
}

resource "aws_s3_bucket_lifecycle_configuration" "canary" {
  bucket = aws_s3_bucket.canary.id
  
  rule {
    id     = "cleanup"
    status = "Enabled"
    
    expiration {
      days = 30
    }
  }
}

# IAM role for CloudWatch Synthetics
resource "aws_iam_role" "canary" {
  name = "${var.project_name}-${var.environment}-canary-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "${var.project_name}-${var.environment}-canary-role"
  }
}

resource "aws_iam_policy" "canary" {
  name        = "${var.project_name}-${var.environment}-canary-policy"
  description = "Policy for CloudWatch Synthetics canaries"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.canary.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:ListBucket"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "CloudWatchSynthetics"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "canary" {
  role       = aws_iam_role.canary.name
  policy_arn = aws_iam_policy.canary.arn
}

# Budget and cost management
resource "aws_budgets_budget" "monthly" {
  name              = "${var.project_name}-${var.environment}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 110
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_email_addresses = var.budget_notification_emails
  }
}
