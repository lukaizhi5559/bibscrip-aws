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

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

variable "backend_image" {
  description = "Docker image for the backend"
  type        = string
}

variable "backend_cpu" {
  description = "CPU units for the backend task"
  type        = number
  default     = 1024
}

variable "backend_memory" {
  description = "Memory for the backend task (MB)"
  type        = number
  default     = 2048
}

variable "backend_container_port" {
  description = "Port for the backend container"
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

variable "backend_secrets" {
  description = "List of secrets for backend container"
  type        = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "lambda_zip_path" {
  description = "Path to the Lambda function ZIP file"
  type        = string
}

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

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}
