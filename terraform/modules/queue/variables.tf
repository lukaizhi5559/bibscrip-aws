variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "kms_key_id" {
  description = "ID of the KMS key for encryption"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
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
