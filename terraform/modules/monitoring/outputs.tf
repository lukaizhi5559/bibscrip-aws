output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "xray_sampling_rule_name" {
  description = "Name of the X-Ray sampling rule"
  value       = aws_xray_sampling_rule.api_tracing.rule_name
}

output "api_canary_id" {
  description = "ID of the API health canary"
  value       = aws_synthetics_canary.api_health.id
}

output "frontend_canary_id" {
  description = "ID of the frontend health canary"
  value       = aws_synthetics_canary.frontend_health.id
}

output "canary_bucket_name" {
  description = "Name of the S3 bucket for canary artifacts"
  value       = aws_s3_bucket.canary.bucket
}

output "monthly_budget_id" {
  description = "ID of the monthly budget"
  value       = aws_budgets_budget.monthly.id
}
