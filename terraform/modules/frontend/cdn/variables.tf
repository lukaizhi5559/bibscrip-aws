variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "domain_name" {
  description = "Main domain name for the application"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "alb_domain_name" {
  description = "Domain name of the ALB for backend"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the ALB for backend"
  type        = string
}

variable "eb_domain_name" {
  description = "Domain name of the Elastic Beanstalk environment"
  type        = string
}

variable "eb_zone_id" {
  description = "Zone ID of the Elastic Beanstalk environment"
  type        = string
}

variable "cloudfront_price_class" {
  description = "Price class for CloudFront distribution"
  type        = string
  default     = "PriceClass_100" # Use PriceClass_All for global, PriceClass_200 for most regions
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  type        = string
  default     = ""
}
