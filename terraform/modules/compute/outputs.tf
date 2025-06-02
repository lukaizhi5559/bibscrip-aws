output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "backend_alb_dns_name" {
  description = "DNS name of the backend ALB"
  value       = aws_lb.backend.dns_name
}

output "backend_alb_zone_id" {
  description = "Zone ID of the backend ALB"
  value       = aws_lb.backend.zone_id
}

output "backend_service_name" {
  description = "Name of the backend ECS service"
  value       = aws_ecs_service.backend.name
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.bible_verse_lookup.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.bible_verse_lookup.arn
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "${aws_apigatewayv2_api.lambda.api_endpoint}/${var.environment}"
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}
