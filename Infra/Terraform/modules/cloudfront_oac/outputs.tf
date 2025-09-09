# Infra/Terraform/modules/cloudfront_oac/outputs.tf

# Bucket name of the private site bucket
output "s3_bucket_name" {
  description = "Private S3 site bucket name"
  value       = aws_s3_bucket.site.bucket
}

# CloudFront distribution ID
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.dist.id
}

# Preferred CDN URL (custom alias if present, otherwise the default CF domain)
output "cdn_url" {
  description = "HTTPS URL for the CDN (custom alias if configured, else CF domain)"
  value       = "https://${try(tolist(aws_cloudfront_distribution.dist.aliases)[0], aws_cloudfront_distribution.dist.domain_name)}"
}