output "cdn_url" {
  value       = "https://${var.cdn_domain}"
  description = "CloudFront URL with your custom domain."
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.dist.id
  description = "CloudFront distribution ID."
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.site.bucket
  description = "Private S3 site bucket."
}

output "logs_bucket_name" {
  value       = aws_s3_bucket.logs.bucket
  description = "CloudFront/S3 access logs bucket."
}