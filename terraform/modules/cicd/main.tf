# S3 bucket for CodePipeline artifacts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.project_name}-${var.environment}-codepipeline-artifacts"

  tags = {
    Name = "${var.project_name}-${var.environment}-codepipeline-artifacts"
  }
}

resource "aws_s3_bucket_ownership_controls" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.codepipeline_artifacts]
}

resource "aws_s3_bucket_lifecycle_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# IAM role for CodePipeline
resource "aws_iam_role" "codepipeline" {
  name = "${var.project_name}-${var.environment}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-codepipeline-role"
  }
}

resource "aws_iam_policy" "codepipeline" {
  name        = "${var.project_name}-${var.environment}-codepipeline-policy"
  description = "Policy for CodePipeline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticbeanstalk:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "s3:*",
          "sns:*",
          "cloudformation:*",
          "rds:*",
          "sqs:*",
          "ecs:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:ListFunctions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.github.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

# CodeStar connection for GitHub
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-${var.environment}-github-connection"
  provider_type = "GitHub"

  tags = {
    Name = "${var.project_name}-${var.environment}-github-connection"
  }
}

# IAM role for CodeBuild
resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-${var.environment}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-codebuild-role"
  }
}

resource "aws_iam_policy" "codebuild" {
  name        = "${var.project_name}-${var.environment}-codebuild-policy"
  description = "Policy for CodeBuild"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*",
          var.frontend_assets_bucket_arn,
          "${var.frontend_assets_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.openai_api_key_secret_arn,
          var.claude_api_key_secret_arn,
          var.gemini_api_key_secret_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

# CodeBuild project for backend
resource "aws_codebuild_project" "backend" {
  name          = "${var.project_name}-${var.environment}-backend"
  description   = "Build project for backend API"
  build_timeout = 30
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true # Required for Docker

    environment_variable {
      name  = "ENV"
      value = var.environment
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = var.backend_ecr_repository_uri
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "backend/buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.environment}-backend"
      stream_name = "build-log"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-build"
  }
}

# CodeBuild project for frontend
resource "aws_codebuild_project" "frontend" {
  name          = "${var.project_name}-${var.environment}-frontend"
  description   = "Build project for frontend"
  build_timeout = 30
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ENV"
      value = var.environment
    }

    environment_variable {
      name  = "S3_BUCKET"
      value = var.frontend_assets_bucket
    }

    environment_variable {
      name  = "CLOUDFRONT_DISTRIBUTION_ID"
      value = var.cloudfront_distribution_id
    }

    environment_variable {
      name  = "API_URL"
      value = var.api_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "frontend/buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-${var.environment}-frontend"
      stream_name = "build-log"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-build"
  }
}

# Lambda function for deployment notification
resource "aws_lambda_function" "deployment_notification" {
  function_name    = "${var.project_name}-${var.environment}-deployment-notification"
  role             = aws_iam_role.lambda_deployment_notification.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.lambda_deployment_notification_zip_path
  source_code_hash = filebase64sha256(var.lambda_deployment_notification_zip_path)
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.deployment_notifications.arn
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-deployment-notification"
  }
}

# IAM role for Lambda deployment notification
resource "aws_iam_role" "lambda_deployment_notification" {
  name = "${var.project_name}-${var.environment}-lambda-deployment-notification-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-deployment-notification-role"
  }
}

resource "aws_iam_policy" "lambda_deployment_notification" {
  name        = "${var.project_name}-${var.environment}-lambda-deployment-notification-policy"
  description = "Policy for Lambda deployment notification"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.deployment_notifications.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_deployment_notification" {
  role       = aws_iam_role.lambda_deployment_notification.name
  policy_arn = aws_iam_policy.lambda_deployment_notification.arn
}

# SNS topic for deployment notifications
resource "aws_sns_topic" "deployment_notifications" {
  name = "${var.project_name}-${var.environment}-deployment-notifications"

  tags = {
    Name = "${var.project_name}-${var.environment}-deployment-notifications"
  }
}

resource "aws_sns_topic_subscription" "deployment_email" {
  count     = length(var.deployment_notification_emails)
  topic_arn = aws_sns_topic.deployment_notifications.arn
  protocol  = "email"
  endpoint  = var.deployment_notification_emails[count.index]
}

# CodePipeline for Backend
resource "aws_codepipeline" "backend" {
  name     = "${var.project_name}-${var.environment}-backend-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repository
        BranchName       = var.environment == "prod" ? "main" : (var.environment == "staging" ? "staging" : "dev")
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildBackend"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.backend.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  stage {
    name = "Notify"

    action {
      name            = "NotifyDeployment"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "Lambda"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        FunctionName   = aws_lambda_function.deployment_notification.function_name
        UserParameters = jsonencode({
          service = "backend"
          environment = var.environment
          status = "deployed"
        })
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-pipeline"
  }
}

# CodePipeline for Frontend
resource "aws_codepipeline" "frontend" {
  name     = "${var.project_name}-${var.environment}-frontend-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repository
        BranchName       = var.environment == "prod" ? "main" : (var.environment == "staging" ? "staging" : "dev")
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildFrontend"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.frontend.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployElasticBeanstalk"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ElasticBeanstalk"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName = var.elastic_beanstalk_application_name
        EnvironmentName = var.elastic_beanstalk_environment_name
      }
    }
  }

  stage {
    name = "Notify"

    action {
      name            = "NotifyDeployment"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "Lambda"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        FunctionName   = aws_lambda_function.deployment_notification.function_name
        UserParameters = jsonencode({
          service = "frontend"
          environment = var.environment
          status = "deployed"
        })
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-pipeline"
  }
}
