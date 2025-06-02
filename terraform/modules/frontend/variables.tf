variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
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

variable "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group (used for EB instances)"
  type        = string
}

variable "nextjs_container_port" {
  description = "Port for NextJS container"
  type        = number
  default     = 3000
}

variable "instance_type" {
  description = "Instance type for Elastic Beanstalk"
  type        = string
  default     = "t3.small"
}

variable "min_instances" {
  description = "Minimum number of instances for auto scaling"
  type        = number
  default     = 2
}

variable "max_instances" {
  description = "Maximum number of instances for auto scaling"
  type        = number
  default     = 10
}

variable "backend_api_url" {
  description = "URL for the backend API"
  type        = string
}
