# Environment outputs (staging) — expose values coming from the module

output "s3_bucket_name" {
  description = "Private S3 site bucket name (from module)"
  value       = module.static_site.s3_bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (from module)"
  value       = module.static_site.cloudfront_distribution_id
}

output "cdn_url" {
  description = "HTTPS URL for the CDN (custom alias if configured, else CF domain)"
  value       = module.static_site.cdn_url
}