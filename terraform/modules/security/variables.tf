variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "waf_block_mode" {
  description = "WAF block mode (COUNT or BLOCK)"
  type        = string
  default     = "BLOCK"
}

variable "blocked_ip_addresses" {
  description = "List of IP addresses to block"
  type        = list(string)
  default     = []
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "claude_api_key" {
  description = "Claude API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Gemini API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "lambda_secret_rotation_zip_path" {
  description = "Path to the Lambda function ZIP file for secret rotation"
  type        = string
  default     = "lambda/secret-rotation.zip"
}
