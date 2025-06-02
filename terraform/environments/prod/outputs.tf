output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of database subnets"
  value       = module.networking.database_subnet_ids
}

output "backend_alb_dns_name" {
  description = "DNS name of the backend ALB"
  value       = module.compute.backend_alb_dns_name
}

output "backend_ecs_service_name" {
  description = "Name of the backend ECS service"
  value       = module.compute.backend_ecs_service_name
}

output "backend_ecs_cluster_name" {
  description = "Name of the backend ECS cluster"
  value       = module.compute.backend_ecs_cluster_name
}

output "api_gateway_endpoint" {
  description = "Endpoint URL of the API Gateway"
  value       = module.compute.api_gateway_endpoint
}

output "frontend_elastic_beanstalk_cname" {
  description = "CNAME of the Elastic Beanstalk environment"
  value       = module.frontend.elastic_beanstalk_cname
}

output "rds_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.database.rds_instance_endpoint
}

output "elasticache_endpoint" {
  description = "Endpoint of the ElastiCache Redis cluster"
  value       = module.database.elasticache_endpoint
}

output "dynamodb_tables" {
  description = "List of DynamoDB table names"
  value       = [
    "${var.project_name}-${var.environment}-user-data",
    "${var.project_name}-${var.environment}-metrics",
    "${var.project_name}-${var.environment}-request-logs"
  ]
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cdn.cloudfront_distribution_domain_name
}

output "route53_records" {
  description = "List of Route53 record domains created"
  value       = module.cdn.route53_records
}

output "sqs_request_queue_url" {
  description = "URL of the SQS request queue"
  value       = module.queue.request_queue_url
}

output "sqs_background_queue_url" {
  description = "URL of the SQS background queue"
  value       = module.queue.background_queue_url
}

output "eventbridge_bus_name" {
  description = "Name of the EventBridge event bus"
  value       = module.queue.event_bus_name
}

output "stepfunctions_state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.queue.sfn_state_machine_arn
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.monitoring.dashboard_name
}

output "cloudwatch_alerts_topic_arn" {
  description = "ARN of the CloudWatch alerts SNS topic"
  value       = module.monitoring.sns_topic_arn
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = module.security.kms_key_id
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = module.security.waf_web_acl_id
}

output "openai_api_key_secret_arn" {
  description = "ARN of the OpenAI API key secret"
  value       = module.security.openai_api_key_secret_arn
}

output "backend_pipeline_name" {
  description = "Name of the backend CodePipeline"
  value       = module.cicd.backend_pipeline_name
}

output "frontend_pipeline_name" {
  description = "Name of the frontend CodePipeline"
  value       = module.cicd.frontend_pipeline_name
}

output "codepipeline_artifacts_bucket" {
  description = "Name of the S3 bucket for CodePipeline artifacts"
  value       = module.cicd.codepipeline_artifacts_bucket
}
