variable "project_name" {
  type        = string
  description = "Short slug used for naming and tags."
}

variable "domain_name" {
  type        = string
  description = "Apex domain hosted in Route 53 (e.g., kevinscloudlab.click)."
}

variable "cdn_domain" {
  type        = string
  description = "FQDN to serve via CloudFront (e.g., cdn.staging.kevinscloudlab.click)."
}

variable "price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "CloudFront price class."
}

variable "enable_ipv6" {
  type        = bool
  default     = true
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags to apply to resources."
}