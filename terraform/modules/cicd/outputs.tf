output "codepipeline_artifacts_bucket" {
  description = "Name of the S3 bucket for CodePipeline artifacts"
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}

output "backend_pipeline_name" {
  description = "Name of the backend CodePipeline"
  value       = aws_codepipeline.backend.name
}

output "frontend_pipeline_name" {
  description = "Name of the frontend CodePipeline"
  value       = aws_codepipeline.frontend.name
}

output "github_connection_arn" {
  description = "ARN of the GitHub connection"
  value       = aws_codestarconnections_connection.github.arn
}

output "codebuild_backend_project_name" {
  description = "Name of the backend CodeBuild project"
  value       = aws_codebuild_project.backend.name
}

output "codebuild_frontend_project_name" {
  description = "Name of the frontend CodeBuild project"
  value       = aws_codebuild_project.frontend.name
}

output "deployment_notification_lambda_name" {
  description = "Name of the deployment notification Lambda function"
  value       = aws_lambda_function.deployment_notification.function_name
}

output "deployment_notification_topic_arn" {
  description = "ARN of the SNS topic for deployment notifications"
  value       = aws_sns_topic.deployment_notifications.arn
}
