output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "openai_api_key_secret_arn" {
  description = "ARN of the OpenAI API key secret"
  value       = aws_secretsmanager_secret.openai_api_key.arn
}

output "claude_api_key_secret_arn" {
  description = "ARN of the Claude API key secret"
  value       = aws_secretsmanager_secret.claude_api_key.arn
}

output "gemini_api_key_secret_arn" {
  description = "ARN of the Gemini API key secret"
  value       = aws_secretsmanager_secret.gemini_api_key.arn
}
