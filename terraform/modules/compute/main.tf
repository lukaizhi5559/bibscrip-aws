# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-logs"
    Environment = var.environment
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-execution-role"
  }
}

# Attach policies to the ECS Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ecr" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECR-FullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-role"
  }
}

# Policies for ECS Task Role
resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.project_name}-${var.environment}-ecs-task-policy"
  description = "Policy for ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:*",
          "s3:*",
          "sqs:*",
          "sns:*",
          "logs:*",
          "elasticache:*",
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# Backend Service
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-${var.environment}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-${var.environment}-backend"
      image     = var.backend_image
      essential = true
      
      portMappings = [
        {
          containerPort = var.backend_container_port
          hostPort      = var.backend_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(var.backend_container_port)
        }
      ]

      secrets = var.backend_secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-task"
  }
}

# Application Load Balancer for Backend
resource "aws_lb" "backend" {
  name               = "${var.project_name}-${var.environment}-backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-alb"
  }
}

# ALB Target Group for Backend
resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-${var.environment}-backend-tg"
  port        = var.backend_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/api/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-tg"
  }
}

# ALB Listener for Backend (HTTP)
resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB Listener for Backend (HTTPS)
resource "aws_lb_listener" "backend_https" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# ECS Service for Backend
resource "aws_ecs_service" "backend" {
  name                               = "${var.project_name}-${var.environment}-backend-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.backend.arn
  desired_count                      = var.backend_min_capacity
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  health_check_grace_period_seconds  = 60

  network_configuration {
    security_groups  = [var.ecs_tasks_security_group_id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "${var.project_name}-${var.environment}-backend"
    container_port   = var.backend_container_port
  }

  depends_on = [aws_lb_listener.backend_https]

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-service"
  }
}

# Auto Scaling for Backend
resource "aws_appautoscaling_target" "backend" {
  max_capacity       = var.backend_max_capacity
  min_capacity       = var.backend_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "backend_cpu" {
  name               = "${var.project_name}-${var.environment}-backend-cpu-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "backend_memory" {
  name               = "${var.project_name}-${var.environment}-backend-memory-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Policy - Request Count Per Target
resource "aws_appautoscaling_policy" "backend_requests" {
  name               = "${var.project_name}-${var.environment}-backend-requests-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.backend.arn_suffix}/${aws_lb_target_group.backend.arn_suffix}"
    }
    target_value       = 1000
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Lambda function for Bible verse lookups
resource "aws_lambda_function" "bible_verse_lookup" {
  function_name    = "${var.project_name}-${var.environment}-bible-verse-lookup"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-bible-verse-lookup"
  }
}

# Lambda execution role
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-${var.environment}-lambda-execution-role"

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
    Name = "${var.project_name}-${var.environment}-lambda-execution-role"
  }
}

# Lambda execution policy
resource "aws_iam_policy" "lambda_execution" {
  name        = "${var.project_name}-${var.environment}-lambda-execution-policy"
  description = "Policy for Lambda execution"

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
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "*"
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

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_execution.arn
}

# API Gateway for Lambda integration
resource "aws_apigatewayv2_api" "lambda" {
  name          = "${var.project_name}-${var.environment}-lambda-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["*"] # Restrict this in production
    max_age       = 300
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-api"
  }
}

# API Gateway integration with Lambda
resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.lambda.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.bible_verse_lookup.invoke_arn
  integration_method = "POST"
}

# API Gateway route
resource "aws_apigatewayv2_route" "lambda" {
  api_id    = aws_apigatewayv2_api.lambda.id
  route_key = "GET /api/verse/{reference}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# API Gateway stage
resource "aws_apigatewayv2_stage" "lambda" {
  api_id      = aws_apigatewayv2_api.lambda.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-stage"
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bible_verse_lookup.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}-lambda-api"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.environment}-apigateway-logs"
  }
}
