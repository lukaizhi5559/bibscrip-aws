output "eb_application_name" {
  description = "Name of the Elastic Beanstalk application"
  value       = aws_elastic_beanstalk_application.frontend.name
}

output "eb_environment_name" {
  description = "Name of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.frontend.name
}

output "eb_environment_cname" {
  description = "CNAME of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.frontend.cname
}

output "eb_environment_endpoint" {
  description = "Endpoint URL of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.frontend.endpoint_url
}

output "eb_load_balancers" {
  description = "Load balancers used by the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.frontend.load_balancers
}

output "eb_versions_bucket" {
  description = "S3 bucket used for application versions"
  value       = aws_s3_bucket.eb_versions.bucket
}

output "eb_ec2_role_name" {
  description = "Name of the EC2 IAM role for Elastic Beanstalk"
  value       = aws_iam_role.eb_ec2.name
}

output "eb_service_role_name" {
  description = "Name of the service IAM role for Elastic Beanstalk"
  value       = aws_iam_role.eb_service.name
}
