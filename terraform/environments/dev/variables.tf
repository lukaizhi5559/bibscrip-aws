variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "bibscrip"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Main domain name for the application"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

# Backend API settings
variable "backend_container_image" {
  description = "Docker image for backend API"
  type        = string
}

variable "backend_container_port" {
  description = "Container port for backend API"
  type        = number
  default     = 8080
}

variable "backend_container_cpu" {
  description = "CPU units for backend container (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "backend_container_memory" {
  description = "Memory for backend container in MiB"
  type        = number
  default     = 1024
}

variable "backend_desired_count" {
  description = "Desired count of backend containers"
  type        = number
  default     = 2
}

variable "backend_min_count" {
  description = "Minimum count of backend containers"
  type        = number
  default     = 1
}

variable "backend_max_count" {
  description = "Maximum count of backend containers"
  type        = number
  default     = 4
}

variable "backend_ecr_repository_uri" {
  description = "URI of the ECR repository for backend container images"
  type        = string
}

# Frontend settings
variable "eb_solution_stack_name" {
  description = "Elastic Beanstalk solution stack name"
  type        = string
  default     = "64bit Amazon Linux 2023 v6.0.2 running Node.js 20"
}

variable "eb_instance_type" {
  description = "Elastic Beanstalk instance type"
  type        = string
  default     = "t3.small"
}

variable "eb_min_instances" {
  description = "Minimum number of instances for Elastic Beanstalk"
  type        = number
  default     = 1
}

variable "eb_max_instances" {
  description = "Maximum number of instances for Elastic Beanstalk"
  type        = number
  default     = 2
}

variable "cloudfront_price_class" {
  description = "Price class for CloudFront distribution"
  type        = string
  default     = "PriceClass_100"
}

# Database settings
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "rds_storage_size" {
  description = "RDS storage size in GB"
  type        = number
  default     = 20
}

variable "rds_engine_version" {
  description = "RDS PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.small"
}

variable "redis_engine_version" {
  description = "ElastiCache Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_parameter_group_name" {
  description = "ElastiCache Redis parameter group name"
  type        = string
  default     = "default.redis7"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

# Lambda settings
variable "lambda_bible_lookup_zip_path" {
  description = "Path to the Lambda function ZIP file for Bible verse lookup"
  type        = string
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda functions in MB"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in seconds"
  type        = number
  default     = 30
}

variable "lambda_daily_cleanup_zip_path" {
  description = "Path to the Lambda function ZIP file for daily cleanup"
  type        = string
}

variable "lambda_try_primary_ai_zip_path" {
  description = "Path to the Lambda function ZIP file for primary AI provider"
  type        = string
}

variable "lambda_try_secondary_ai_zip_path" {
  description = "Path to the Lambda function ZIP file for secondary AI provider"
  type        = string
}

variable "lambda_try_tertiary_ai_zip_path" {
  description = "Path to the Lambda function ZIP file for tertiary AI provider"
  type        = string
}

variable "lambda_secret_rotation_zip_path" {
  description = "Path to the Lambda function ZIP file for secret rotation"
  type        = string
}

variable "lambda_deployment_notification_zip_path" {
  description = "Path to the Lambda function ZIP file for deployment notification"
  type        = string
}

# API keys
variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "claude_api_key" {
  description = "Claude API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gemini_api_key" {
  description = "Gemini API key"
  type        = string
  sensitive   = true
  default     = ""
}

# CI/CD settings
variable "github_repository" {
  description = "GitHub repository in the format owner/repo"
  type        = string
}

variable "deployment_notification_emails" {
  description = "List of email addresses for deployment notifications"
  type        = list(string)
  default     = []
}

# Monitoring settings
variable "alert_email" {
  description = "Email address for alerts"
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
