output "request_queue_url" {
  description = "URL of the request queue"
  value       = aws_sqs_queue.request_queue.url
}

output "request_queue_arn" {
  description = "ARN of the request queue"
  value       = aws_sqs_queue.request_queue.arn
}

output "request_dlq_url" {
  description = "URL of the request dead-letter queue"
  value       = aws_sqs_queue.request_dlq.url
}

output "background_queue_url" {
  description = "URL of the background queue"
  value       = aws_sqs_queue.background_queue.url
}

output "background_queue_arn" {
  description = "ARN of the background queue"
  value       = aws_sqs_queue.background_queue.arn
}

output "background_dlq_url" {
  description = "URL of the background dead-letter queue"
  value       = aws_sqs_queue.background_dlq.url
}

output "event_bus_name" {
  description = "Name of the EventBridge event bus"
  value       = aws_cloudwatch_event_bus.main.name
}

output "event_bus_arn" {
  description = "ARN of the EventBridge event bus"
  value       = aws_cloudwatch_event_bus.main.arn
}

output "sfn_state_machine_arn" {
  description = "ARN of the Step Function state machine"
  value       = aws_sfn_state_machine.ai_orchestration.arn
}

output "sqs_access_policy_arn" {
  description = "ARN of the SQS access policy"
  value       = aws_iam_policy.sqs_access.arn
}
