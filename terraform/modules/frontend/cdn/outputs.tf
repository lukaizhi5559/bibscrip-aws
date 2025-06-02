output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.arn
}

output "s3_static_assets_bucket" {
  description = "S3 bucket name for static assets"
  value       = aws_s3_bucket.static_assets.bucket
}

output "s3_static_assets_arn" {
  description = "ARN of the S3 bucket for static assets"
  value       = aws_s3_bucket.static_assets.arn
}

output "route53_records" {
  description = "List of Route53 record domains created"
  value       = [
    aws_route53_record.main.fqdn,
    aws_route53_record.www.fqdn,
    aws_route53_record.api.fqdn
  ]
}
