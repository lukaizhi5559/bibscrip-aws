# S3 bucket for application versions
resource "aws_s3_bucket" "eb_versions" {
  bucket = "${var.project_name}-${var.environment}-eb-versions"

  tags = {
    Name = "${var.project_name}-${var.environment}-eb-versions"
  }
}

# S3 bucket policy for version bucket
resource "aws_s3_bucket_policy" "eb_versions" {
  bucket = aws_s3_bucket.eb_versions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetObjectAcl"
        ]
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
        Resource = "${aws_s3_bucket.eb_versions.arn}/*"
      }
    ]
  })
}

# Configure bucket lifecycle for versions
resource "aws_s3_bucket_lifecycle_configuration" "eb_versions" {
  bucket = aws_s3_bucket.eb_versions.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "frontend" {
  name        = "${var.project_name}-${var.environment}"
  description = "${var.project_name} ${var.environment} frontend application"

  appversion_lifecycle {
    service_role          = aws_iam_role.eb_service.arn
    max_count             = 10
    delete_source_from_s3 = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-application"
  }
}

# IAM instance profile for Elastic Beanstalk
resource "aws_iam_role" "eb_ec2" {
  name = "${var.project_name}-${var.environment}-eb-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-eb-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  role       = aws_iam_role.eb_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "eb_multicontainer_docker" {
  role       = aws_iam_role.eb_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_instance_profile" "eb_ec2" {
  name = "${var.project_name}-${var.environment}-eb-ec2-profile"
  role = aws_iam_role.eb_ec2.name
}

# IAM service role for Elastic Beanstalk
resource "aws_iam_role" "eb_service" {
  name = "${var.project_name}-${var.environment}-eb-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-eb-service-role"
  }
}

resource "aws_iam_role_policy_attachment" "eb_enhanced_health" {
  role       = aws_iam_role.eb_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "eb_service" {
  role       = aws_iam_role.eb_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

# Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "frontend" {
  name                = "${var.project_name}-${var.environment}"
  application         = aws_elastic_beanstalk_application.frontend.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.0.2 running Node.js 20"
  tier                = "WebServer"
  
  # VPC and networking
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", var.private_subnet_ids)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", var.public_subnet_ids)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "false"
  }

  # Load balancer
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service.name
  }
  
  # Instance settings
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = var.ecs_tasks_security_group_id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  # Auto scaling
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = var.min_instances
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = var.max_instances
  }

  # Scaling trigger
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Percent"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "70"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "30"
  }

  # Health reporting
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "HealthCheckSuccessThreshold"
    value     = "Ok"
  }

  # Load balancer settings
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/api/health"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = var.nextjs_container_port
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  # Next.js environment variables
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = var.environment
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = var.nextjs_container_port
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "BACKEND_API_URL"
    value     = var.backend_api_url
  }

  # Enable termination protection in production
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  # Enable managed platform updates
  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "PreferredStartTime"
    value     = "Sun:02:00"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = "minor"
  }

  # Deployment settings for Blue/Green
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = var.environment == "prod" ? "Immutable" : "Rolling"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "30"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Percentage"
  }

  # Logs streaming to CloudWatch
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = var.environment == "prod" ? "false" : "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = var.environment == "prod" ? "30" : "7"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-eb-environment"
  }

  # Wait for environment to be ready
  wait_for_ready_timeout = "20m"
}

# Initial application version (placeholder)
resource "aws_elastic_beanstalk_application_version" "initial" {
  name        = "${var.project_name}-${var.environment}-initial"
  application = aws_elastic_beanstalk_application.frontend.name
  description = "Initial version"
  bucket      = aws_s3_bucket.eb_versions.id
  key         = "initial-version.zip"

  # Create an empty zip file
  provisioner "local-exec" {
    command = "zip -r initial-version.zip . -i index.js package.json && aws s3 cp initial-version.zip s3://${aws_s3_bucket.eb_versions.bucket}/initial-version.zip"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-initial-version"
  }
}
