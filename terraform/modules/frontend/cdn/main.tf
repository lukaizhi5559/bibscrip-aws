# S3 bucket for static assets
resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.project_name}-${var.environment}-static-assets"

  tags = {
    Name = "${var.project_name}-${var.environment}-static-assets"
  }
}

# S3 bucket ACL
resource "aws_s3_bucket_ownership_controls" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "static_assets" {
  depends_on = [aws_s3_bucket_ownership_controls.static_assets]
  bucket     = aws_s3_bucket.static_assets.id
  acl        = "private"
}

# S3 bucket policy - Allow CloudFront access
resource "aws_s3_bucket_policy" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.static_assets.arn}/*"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
      }
    ]
  })
}

# S3 bucket CORS configuration
resource "aws_s3_bucket_cors_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://${var.domain_name}", "https://*.${var.domain_name}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.project_name} ${var.environment}"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} ${var.environment} CDN"
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  wait_for_deployment = false
  
  # S3 static assets origin
  origin {
    domain_name = aws_s3_bucket.static_assets.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.static_assets.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Load balancer origin for API (backend)
  origin {
    domain_name = var.alb_domain_name
    origin_id   = "ALB-Backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Elastic Beanstalk origin for frontend
  origin {
    domain_name = var.eb_domain_name
    origin_id   = "EB-Frontend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default cache behavior (frontend)
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "EB-Frontend"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["Host", "Origin", "Authorization", "CloudFront-Forwarded-Proto"]
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Cache behavior for static assets
  ordered_cache_behavior {
    path_pattern     = "/_next/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${aws_s3_bucket.static_assets.id}"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior for API routes
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-Backend"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Custom error responses
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL certificate
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Web Application Firewall
  web_acl_id = var.waf_web_acl_arn

  tags = {
    Name = "${var.project_name}-${var.environment}-cdn"
  }
}

# Route53 record for main domain
resource "aws_route53_record" "main" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route53 record for www subdomain
resource "aws_route53_record" "www" {
  zone_id = var.route53_zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route53 record for API subdomain
resource "aws_route53_record" "api" {
  zone_id = var.route53_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_domain_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Route53 health check for the main domain
resource "aws_route53_health_check" "main" {
  fqdn              = var.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/api/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-health-check"
  }
}

# Route53 failover routing policy
resource "aws_route53_record" "failover_primary" {
  zone_id                          = var.route53_zone_id
  name                             = var.domain_name
  type                             = "A"
  failover_routing_policy {
    type = "PRIMARY"
  }
  health_check_id                  = aws_route53_health_check.main.id
  set_identifier                   = "primary"
  
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "failover_secondary" {
  zone_id                          = var.route53_zone_id
  name                             = var.domain_name
  type                             = "A"
  failover_routing_policy {
    type = "SECONDARY"
  }
  set_identifier                   = "secondary"
  
  alias {
    name                   = var.eb_domain_name
    zone_id                = var.eb_zone_id
    evaluate_target_health = false
  }
}
