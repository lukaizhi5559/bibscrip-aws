# SQS Queue for request batching
resource "aws_sqs_queue" "request_queue" {
  name                        = "${var.project_name}-${var.environment}-request-queue"
  delay_seconds               = 0
  max_message_size            = 262144 # 256 KB
  message_retention_seconds   = 86400  # 1 day
  receive_wait_time_seconds   = 10     # Long polling
  visibility_timeout_seconds  = 60
  fifo_queue                  = false
  kms_master_key_id           = var.kms_key_id
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.request_dlq.arn
    maxReceiveCount     = 5
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-request-queue"
  }
}

# SQS Dead Letter Queue for request queue
resource "aws_sqs_queue" "request_dlq" {
  name                        = "${var.project_name}-${var.environment}-request-dlq"
  delay_seconds               = 0
  max_message_size            = 262144 # 256 KB
  message_retention_seconds   = 1209600 # 14 days
  receive_wait_time_seconds   = 10     # Long polling
  kms_master_key_id           = var.kms_key_id
  kms_data_key_reuse_period_seconds = 300

  tags = {
    Name = "${var.project_name}-${var.environment}-request-dlq"
  }
}

# SQS Queue for background processing
resource "aws_sqs_queue" "background_queue" {
  name                        = "${var.project_name}-${var.environment}-background-queue"
  delay_seconds               = 0
  max_message_size            = 262144 # 256 KB
  message_retention_seconds   = 345600 # 4 days
  receive_wait_time_seconds   = 10     # Long polling
  visibility_timeout_seconds  = 300    # 5 minutes
  fifo_queue                  = false
  kms_master_key_id           = var.kms_key_id
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.background_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-background-queue"
  }
}

# SQS Dead Letter Queue for background queue
resource "aws_sqs_queue" "background_dlq" {
  name                        = "${var.project_name}-${var.environment}-background-dlq"
  delay_seconds               = 0
  max_message_size            = 262144 # 256 KB
  message_retention_seconds   = 1209600 # 14 days
  receive_wait_time_seconds   = 10     # Long polling
  kms_master_key_id           = var.kms_key_id
  kms_data_key_reuse_period_seconds = 300

  tags = {
    Name = "${var.project_name}-${var.environment}-background-dlq"
  }
}

# IAM Policy for SQS queue access
resource "aws_iam_policy" "sqs_access" {
  name        = "${var.project_name}-${var.environment}-sqs-access-policy"
  description = "Policy for SQS queue access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = [
          aws_sqs_queue.request_queue.arn,
          aws_sqs_queue.background_queue.arn
        ]
      }
    ]
  })
}

# EventBridge Event Bus
resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.project_name}-${var.environment}-event-bus"

  tags = {
    Name = "${var.project_name}-${var.environment}-event-bus"
  }
}

# EventBridge Rule for scheduled tasks
resource "aws_cloudwatch_event_rule" "daily_cleanup" {
  name                = "${var.project_name}-${var.environment}-daily-cleanup"
  description         = "Daily cleanup tasks"
  schedule_expression = "cron(0 3 * * ? *)" # 3:00 AM UTC every day
  event_bus_name      = aws_cloudwatch_event_bus.main.name

  tags = {
    Name = "${var.project_name}-${var.environment}-daily-cleanup"
  }
}

# EventBridge Target for scheduled tasks
resource "aws_cloudwatch_event_target" "daily_cleanup" {
  rule           = aws_cloudwatch_event_rule.daily_cleanup.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = aws_lambda_function.daily_cleanup.arn
}

# Lambda function for daily cleanup
resource "aws_lambda_function" "daily_cleanup" {
  function_name    = "${var.project_name}-${var.environment}-daily-cleanup"
  role             = aws_iam_role.lambda_event_bridge.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.lambda_daily_cleanup_zip_path
  source_code_hash = filebase64sha256(var.lambda_daily_cleanup_zip_path)
  timeout          = 300
  memory_size      = 256

  environment {
    variables = {
      ENVIRONMENT = var.environment,
      DDB_TABLE_PREFIX = "${var.project_name}-${var.environment}"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-daily-cleanup"
  }
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.daily_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cleanup.arn
}

# IAM role for Lambda EventBridge
resource "aws_iam_role" "lambda_event_bridge" {
  name = "${var.project_name}-${var.environment}-lambda-event-bridge-role"

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
    Name = "${var.project_name}-${var.environment}-lambda-event-bridge-role"
  }
}

# IAM policy for Lambda EventBridge
resource "aws_iam_policy" "lambda_event_bridge" {
  name        = "${var.project_name}-${var.environment}-lambda-event-bridge-policy"
  description = "Policy for Lambda EventBridge function"

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
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:*:*:table/${var.project_name}-${var.environment}*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_event_bridge" {
  role       = aws_iam_role.lambda_event_bridge.name
  policy_arn = aws_iam_policy.lambda_event_bridge.arn
}

# Step Function for AI request orchestration
resource "aws_sfn_state_machine" "ai_orchestration" {
  name     = "${var.project_name}-${var.environment}-ai-orchestration"
  role_arn = aws_iam_role.step_function.arn

  definition = <<EOF
{
  "Comment": "AI Request Orchestration",
  "StartAt": "Try Primary AI Provider",
  "States": {
    "Try Primary AI Provider": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.try_primary_ai.arn}",
      "Retry": [
        {
          "ErrorEquals": ["States.ALL"],
          "IntervalSeconds": 1,
          "MaxAttempts": 2,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "Try Secondary AI Provider"
        }
      ],
      "Next": "Success"
    },
    "Try Secondary AI Provider": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.try_secondary_ai.arn}",
      "Retry": [
        {
          "ErrorEquals": ["States.ALL"],
          "IntervalSeconds": 1,
          "MaxAttempts": 2,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "Try Tertiary AI Provider"
        }
      ],
      "Next": "Success"
    },
    "Try Tertiary AI Provider": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.try_tertiary_ai.arn}",
      "Retry": [
        {
          "ErrorEquals": ["States.ALL"],
          "IntervalSeconds": 1,
          "MaxAttempts": 2,
          "BackoffRate": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "Fail"
        }
      ],
      "Next": "Success"
    },
    "Success": {
      "Type": "Succeed"
    },
    "Fail": {
      "Type": "Fail",
      "Error": "AllProvidersFailedError",
      "Cause": "All AI providers failed to process the request"
    }
  }
}
EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-ai-orchestration"
  }
}

# IAM role for Step Function
resource "aws_iam_role" "step_function" {
  name = "${var.project_name}-${var.environment}-step-function-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-step-function-role"
  }
}

# IAM policy for Step Function
resource "aws_iam_policy" "step_function" {
  name        = "${var.project_name}-${var.environment}-step-function-policy"
  description = "Policy for Step Function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.try_primary_ai.arn,
          aws_lambda_function.try_secondary_ai.arn,
          aws_lambda_function.try_tertiary_ai.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_function" {
  role       = aws_iam_role.step_function.name
  policy_arn = aws_iam_policy.step_function.arn
}

# Lambda functions for AI providers
resource "aws_lambda_function" "try_primary_ai" {
  function_name    = "${var.project_name}-${var.environment}-try-primary-ai"
  role             = aws_iam_role.lambda_ai.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.lambda_try_primary_ai_zip_path
  source_code_hash = filebase64sha256(var.lambda_try_primary_ai_zip_path)
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      ENVIRONMENT = var.environment,
      OPENAI_API_KEY_SECRET_ARN = var.openai_api_key_secret_arn
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-try-primary-ai"
  }
}

resource "aws_lambda_function" "try_secondary_ai" {
  function_name    = "${var.project_name}-${var.environment}-try-secondary-ai"
  role             = aws_iam_role.lambda_ai.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.lambda_try_secondary_ai_zip_path
  source_code_hash = filebase64sha256(var.lambda_try_secondary_ai_zip_path)
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      ENVIRONMENT = var.environment,
      CLAUDE_API_KEY_SECRET_ARN = var.claude_api_key_secret_arn
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-try-secondary-ai"
  }
}

resource "aws_lambda_function" "try_tertiary_ai" {
  function_name    = "${var.project_name}-${var.environment}-try-tertiary-ai"
  role             = aws_iam_role.lambda_ai.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.lambda_try_tertiary_ai_zip_path
  source_code_hash = filebase64sha256(var.lambda_try_tertiary_ai_zip_path)
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      ENVIRONMENT = var.environment,
      GEMINI_API_KEY_SECRET_ARN = var.gemini_api_key_secret_arn
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-try-tertiary-ai"
  }
}

# IAM role for Lambda AI
resource "aws_iam_role" "lambda_ai" {
  name = "${var.project_name}-${var.environment}-lambda-ai-role"

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
    Name = "${var.project_name}-${var.environment}-lambda-ai-role"
  }
}

# IAM policy for Lambda AI
resource "aws_iam_policy" "lambda_ai" {
  name        = "${var.project_name}-${var.environment}-lambda-ai-policy"
  description = "Policy for Lambda AI functions"

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
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.openai_api_key_secret_arn,
          var.claude_api_key_secret_arn,
          var.gemini_api_key_secret_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          "arn:aws:dynamodb:*:*:table/${var.project_name}-${var.environment}*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = var.kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ai" {
  role       = aws_iam_role.lambda_ai.name
  policy_arn = aws_iam_policy.lambda_ai.arn
}
