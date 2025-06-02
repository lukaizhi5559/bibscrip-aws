# KMS key for encrypting sensitive data
resource "aws_kms_key" "main" {
  description             = "${var.project_name}-${var.environment}-key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-${var.environment}-kms-key"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# AWS WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-${var.environment}-web-acl"
  description = "WAF Web ACL for ${var.project_name} ${var.environment}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # AWS Managed Rules
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-aws-common"
      sampled_requests_enabled   = true
    }
  }

  # SQL Injection Rules
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-aws-sqli"
      sampled_requests_enabled   = true
    }
  }

  # Known Bad Inputs Rules
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-aws-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # Bot Control Rules (only in prod)
  dynamic "rule" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      name     = "AWS-AWSManagedRulesBotControlRuleSet"
      priority = 4

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesBotControlRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.project_name}-${var.environment}-aws-bot-control"
        sampled_requests_enabled   = true
      }
    }
  }

  # Rate-based rule to prevent DDoS
  rule {
    name     = "RateBasedRule"
    priority = 5

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.environment == "prod" ? 3000 : 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # Custom rule to block specific IPs if needed
  rule {
    name     = "BlockedIPs"
    priority = 10

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blocked.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-blocked-ips"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-web-acl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-acl"
  }
}

# IP Set for blocked IPs
resource "aws_wafv2_ip_set" "blocked" {
  name               = "${var.project_name}-${var.environment}-blocked-ips"
  description        = "Blocked IP addresses"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.blocked_ip_addresses

  tags = {
    Name = "${var.project_name}-${var.environment}-blocked-ips"
  }
}

# Secrets Manager for API keys
resource "aws_secretsmanager_secret" "openai_api_key" {
  name                    = "${var.project_name}/${var.environment}/openai-api-key"
  description             = "OpenAI API key for ${var.project_name} ${var.environment}"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-openai-api-key"
  }
}

resource "aws_secretsmanager_secret_version" "openai_api_key" {
  count         = var.openai_api_key != "" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = var.openai_api_key
}

resource "aws_secretsmanager_secret" "claude_api_key" {
  name                    = "${var.project_name}/${var.environment}/claude-api-key"
  description             = "Claude API key for ${var.project_name} ${var.environment}"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-claude-api-key"
  }
}

resource "aws_secretsmanager_secret_version" "claude_api_key" {
  count         = var.claude_api_key != "" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.claude_api_key.id
  secret_string = var.claude_api_key
}

resource "aws_secretsmanager_secret" "gemini_api_key" {
  name                    = "${var.project_name}/${var.environment}/gemini-api-key"
  description             = "Gemini API key for ${var.project_name} ${var.environment}"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-gemini-api-key"
  }
}

resource "aws_secretsmanager_secret_version" "gemini_api_key" {
  count         = var.gemini_api_key != "" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.gemini_api_key.id
  secret_string = var.gemini_api_key
}

# Secret rotation
resource "aws_secretsmanager_secret_rotation" "openai_api_key" {
  count               = var.environment == "prod" ? 1 : 0
  secret_id           = aws_secretsmanager_secret.openai_api_key.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret[0].arn

  rotation_rules {
    automatically_after_days = 90
  }
}

# Lambda function for secret rotation (only in prod)
resource "aws_lambda_function" "rotate_secret" {
  count         = var.environment == "prod" ? 1 : 0
  function_name = "${var.project_name}-${var.environment}-rotate-secret"
  role          = aws_iam_role.lambda_secret_rotation[0].arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  filename      = var.lambda_secret_rotation_zip_path
  timeout       = 60

  environment {
    variables = {
      KMS_KEY_ID = aws_kms_key.main.id
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rotate-secret"
  }
}

# IAM role for Lambda secret rotation
resource "aws_iam_role" "lambda_secret_rotation" {
  count = var.environment == "prod" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-lambda-secret-rotation-role"

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
    Name = "${var.project_name}-${var.environment}-lambda-secret-rotation-role"
  }
}

resource "aws_iam_policy" "lambda_secret_rotation" {
  count       = var.environment == "prod" ? 1 : 0
  name        = "${var.project_name}-${var.environment}-lambda-secret-rotation-policy"
  description = "Policy for Lambda secret rotation"

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
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = [
          aws_secretsmanager_secret.openai_api_key.arn,
          aws_secretsmanager_secret.claude_api_key.arn,
          aws_secretsmanager_secret.gemini_api_key.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secret_rotation" {
  count      = var.environment == "prod" ? 1 : 0
  role       = aws_iam_role.lambda_secret_rotation[0].name
  policy_arn = aws_iam_policy.lambda_secret_rotation[0].arn
}
