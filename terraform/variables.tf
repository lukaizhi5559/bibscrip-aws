variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Valid values for environment are: dev, staging, or prod"
  }
}

variable "project_name" {
  description = "Project name to be used for resource naming"
  type        = string
  default     = "bibscrip"
}

variable "domain_name" {
  description = "Main domain name for the application"
  type        = string
}

variable "enable_cdn" {
  description = "Enable CloudFront distribution"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Frontend variables
variable "nextjs_container_port" {
  description = "Port for NextJS container"
  type        = number
  default     = 3000
}

variable "frontend_min_capacity" {
  description = "Minimum capacity for frontend auto scaling"
  type        = number
  default     = 2
}

variable "frontend_max_capacity" {
  description = "Maximum capacity for frontend auto scaling"
  type        = number
  default     = 10
}

# Backend variables
variable "backend_container_port" {
  description = "Port for backend container"
  type        = number
  default     = 8080
}

variable "backend_min_capacity" {
  description = "Minimum capacity for backend auto scaling"
  type        = number
  default     = 2
}

variable "backend_max_capacity" {
  description = "Maximum capacity for backend auto scaling"
  type        = number
  default     = 20
}

# Database variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "bibscrip"
}

variable "db_username" {
  description = "Username for database"
  type        = string
  sensitive   = true
}

variable "db_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = true
}

# Redis variables
variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.medium"
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis cache nodes"
  type        = number
  default     = 2
}

# DynamoDB variables
variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

# Lambda variables
variable "lambda_memory_size" {
  description = "Memory size for Lambda functions in MB"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in seconds"
  type        = number
  default     = 30
}

# WAF variables
variable "waf_block_mode" {
  description = "WAF block mode (COUNT or BLOCK)"
  type        = string
  default     = "BLOCK"
}

# Budget variables
variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 1000
}

variable "budget_notification_emails" {
  description = "List of email addresses to notify for budget alerts"
  type        = list(string)
  default     = []
}

# CI/CD variables
variable "github_repo" {
  description = "GitHub repository for CI/CD"
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "GitHub branch for CI/CD"
  type        = string
  default     = "main"
}

# API keys and secrets
variable "openai_api_key_arn" {
  description = "ARN of the OpenAI API key in Secrets Manager"
  type        = string
  default     = ""
}

variable "claude_api_key_arn" {
  description = "ARN of the Claude API key in Secrets Manager"
  type        = string
  default     = ""
}

variable "gemini_api_key_arn" {
  description = "ARN of the Gemini API key in Secrets Manager"
  type        = string
  default     = ""
}
