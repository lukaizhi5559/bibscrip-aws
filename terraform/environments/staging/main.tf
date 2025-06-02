provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Terraform   = "true"
      Owner       = "DevOps"
    }
  }
}

# For resources that must be created in us-east-1 (e.g., CloudFront, ACM)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Terraform   = "true"
      Owner       = "DevOps"
    }
  }
}

# Networking module
module "networking" {
  source = "../../modules/networking"

  project_name  = var.project_name
  environment   = var.environment
  aws_region    = var.aws_region
  vpc_cidr      = var.vpc_cidr
  azs           = var.availability_zones
}

# Security module
module "security" {
  source = "../../modules/security"

  project_name              = var.project_name
  environment               = var.environment
  openai_api_key            = var.openai_api_key
  claude_api_key            = var.claude_api_key
  gemini_api_key            = var.gemini_api_key
  lambda_secret_rotation_zip_path = var.lambda_secret_rotation_zip_path
}

# Database module
module "database" {
  source = "../../modules/database"

  project_name   = var.project_name
  environment    = var.environment
  aws_region     = var.aws_region
  
  # RDS settings
  rds_instance_class = var.rds_instance_class
  rds_storage_size   = var.rds_storage_size
  rds_engine_version = var.rds_engine_version
  rds_multi_az       = true  # Enable multi-AZ for staging
  
  # Networking
  vpc_id                  = module.networking.vpc_id
  database_subnet_ids     = module.networking.database_subnet_ids
  database_security_group_id = module.networking.rds_security_group_id
  
  # Redis settings
  redis_node_type     = var.redis_node_type
  redis_engine_version = var.redis_engine_version
  redis_parameter_group_name = var.redis_parameter_group_name
  redis_multi_az      = true  # Enable multi-AZ for staging
  
  # DynamoDB settings
  dynamodb_billing_mode = var.dynamodb_billing_mode
  
  # Security
  kms_key_id          = module.security.kms_key_id
}

# Compute module for backend
module "compute" {
  source = "../../modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  
  # Networking
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
  ecs_security_group_id = module.networking.ecs_security_group_id
  alb_security_group_id = module.networking.alb_security_group_id
  
  # ECS settings
  backend_container_image = var.backend_container_image
  backend_container_port  = var.backend_container_port
  backend_container_cpu   = var.backend_container_cpu
  backend_container_memory = var.backend_container_memory
  backend_desired_count   = var.backend_desired_count
  backend_max_count       = var.backend_max_count
  backend_min_count       = var.backend_min_count
  
  # Lambda settings
  lambda_bible_lookup_zip_path = var.lambda_bible_lookup_zip_path
  lambda_memory_size        = var.lambda_memory_size
  lambda_timeout            = var.lambda_timeout
  
  # API secrets
  openai_api_key_secret_arn = module.security.openai_api_key_secret_arn
  claude_api_key_secret_arn = module.security.claude_api_key_secret_arn
  gemini_api_key_secret_arn = module.security.gemini_api_key_secret_arn
  
  # Certificates
  acm_certificate_arn     = var.acm_certificate_arn
}

# Frontend module
module "frontend" {
  source = "../../modules/frontend"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  
  # Networking
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  
  # Elastic Beanstalk settings
  eb_solution_stack_name = var.eb_solution_stack_name
  eb_instance_type     = var.eb_instance_type
  eb_min_instances     = var.eb_min_instances
  eb_max_instances     = var.eb_max_instances
  
  # Backend connection
  backend_api_url     = module.compute.backend_alb_dns_name
}

# CDN module
module "cdn" {
  source = "../../modules/frontend/cdn"
  providers = {
    aws = aws.us-east-1
  }

  project_name       = var.project_name
  environment        = var.environment
  domain_name        = var.domain_name
  
  # Route53
  route53_zone_id    = var.route53_zone_id
  
  # SSL/TLS
  acm_certificate_arn = var.acm_certificate_arn
  
  # Origins
  alb_domain_name    = module.compute.backend_alb_dns_name
  alb_zone_id        = module.compute.backend_alb_zone_id
  eb_domain_name     = module.frontend.elastic_beanstalk_cname
  eb_zone_id         = module.frontend.elastic_beanstalk_zone_id
  
  # Security
  waf_web_acl_arn    = module.security.waf_web_acl_arn
  
  # CloudFront
  cloudfront_price_class = var.cloudfront_price_class
}

# Queue module
module "queue" {
  source = "../../modules/queue"

  project_name       = var.project_name
  environment        = var.environment
  
  # Security
  kms_key_id         = module.security.kms_key_id
  kms_key_arn        = module.security.kms_key_arn
  openai_api_key_secret_arn = module.security.openai_api_key_secret_arn
  claude_api_key_secret_arn = module.security.claude_api_key_secret_arn
  gemini_api_key_secret_arn = module.security.gemini_api_key_secret_arn
  
  # Lambda function paths
  lambda_daily_cleanup_zip_path = var.lambda_daily_cleanup_zip_path
  lambda_try_primary_ai_zip_path = var.lambda_try_primary_ai_zip_path
  lambda_try_secondary_ai_zip_path = var.lambda_try_secondary_ai_zip_path
  lambda_try_tertiary_ai_zip_path = var.lambda_try_tertiary_ai_zip_path
}

# Monitoring module
module "monitoring" {
  source = "../../modules/monitoring"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  
  # Resources to monitor
  alb_arn_suffix     = module.compute.backend_alb_arn_suffix
  cloudfront_distribution_id = module.cdn.cloudfront_distribution_id
  ecs_service_name   = module.compute.backend_ecs_service_name
  ecs_cluster_name   = module.compute.backend_ecs_cluster_name
  rds_instance_id    = module.database.rds_instance_id
  elasticache_cluster_id = module.database.elasticache_cluster_id
  dynamodb_user_table = "${var.project_name}-${var.environment}-user-data"
  lambda_function_name = module.compute.lambda_function_name
  request_queue_name  = module.queue.request_queue_url
  api_gateway_id     = module.compute.api_gateway_id
  waf_web_acl_name   = module.security.waf_web_acl_id
  
  # Alerting
  alert_email        = var.alert_email
  s3_canary_bucket   = "${var.project_name}-${var.environment}-canary-bucket"
  monthly_budget_amount = var.monthly_budget_amount
  budget_notification_emails = var.budget_notification_emails
}

# CI/CD module
module "cicd" {
  source = "../../modules/cicd"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  
  # GitHub
  github_repository  = var.github_repository
  
  # ECR
  backend_ecr_repository_uri = var.backend_ecr_repository_uri
  
  # Frontend
  frontend_assets_bucket = module.cdn.s3_static_assets_bucket
  frontend_assets_bucket_arn = module.cdn.s3_static_assets_arn
  cloudfront_distribution_id = module.cdn.cloudfront_distribution_id
  api_url             = "https://api.${var.domain_name}"
  
  # Deployment targets
  ecs_cluster_name    = module.compute.backend_ecs_cluster_name
  ecs_service_name    = module.compute.backend_ecs_service_name
  elastic_beanstalk_application_name = module.frontend.elastic_beanstalk_application_name
  elastic_beanstalk_environment_name = module.frontend.elastic_beanstalk_environment_name
  
  # Secrets
  openai_api_key_secret_arn = module.security.openai_api_key_secret_arn
  claude_api_key_secret_arn = module.security.claude_api_key_secret_arn
  gemini_api_key_secret_arn = module.security.gemini_api_key_secret_arn
  
  # Lambda
  lambda_deployment_notification_zip_path = var.lambda_deployment_notification_zip_path
  
  # Notification
  deployment_notification_emails = var.deployment_notification_emails
}
