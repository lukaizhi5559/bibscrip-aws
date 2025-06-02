variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "rds_instance_id" {
  description = "ID of the RDS instance"
  type        = string
}

variable "elasticache_cluster_id" {
  description = "ID of the ElastiCache cluster"
  type        = string
}

variable "dynamodb_user_table" {
  description = "Name of the DynamoDB user table"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the main Lambda function"
  type        = string
}

variable "request_queue_name" {
  description = "Name of the request SQS queue"
  type        = string
}

variable "api_gateway_id" {
  description = "ID of the API Gateway"
  type        = string
}

variable "waf_web_acl_name" {
  description = "Name of the WAF Web ACL"
  type        = string
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}

variable "s3_canary_bucket" {
  description = "Name of the S3 bucket for CloudWatch Synthetics canaries"
  type        = string
  default     = ""
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 100
}

variable "budget_notification_emails" {
  description = "List of email addresses for budget notifications"
  type        = list(string)
  default     = []
}
