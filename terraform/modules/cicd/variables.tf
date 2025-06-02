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

variable "github_repository" {
  description = "GitHub repository in the format owner/repo"
  type        = string
}

variable "backend_ecr_repository_uri" {
  description = "URI of the ECR repository for backend container images"
  type        = string
}

variable "frontend_assets_bucket" {
  description = "Name of the S3 bucket for frontend static assets"
  type        = string
}

variable "frontend_assets_bucket_arn" {
  description = "ARN of the S3 bucket for frontend static assets"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  type        = string
}

variable "api_url" {
  description = "URL of the backend API"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "elastic_beanstalk_application_name" {
  description = "Name of the Elastic Beanstalk application"
  type        = string
}

variable "elastic_beanstalk_environment_name" {
  description = "Name of the Elastic Beanstalk environment"
  type        = string
}

variable "openai_api_key_secret_arn" {
  description = "ARN of the OpenAI API key secret"
  type        = string
}

variable "claude_api_key_secret_arn" {
  description = "ARN of the Claude API key secret"
  type        = string
}

variable "gemini_api_key_secret_arn" {
  description = "ARN of the Gemini API key secret"
  type        = string
}

variable "lambda_deployment_notification_zip_path" {
  description = "Path to the Lambda function ZIP file for deployment notification"
  type        = string
}

variable "deployment_notification_emails" {
  description = "List of email addresses for deployment notifications"
  type        = list(string)
  default     = []
}
