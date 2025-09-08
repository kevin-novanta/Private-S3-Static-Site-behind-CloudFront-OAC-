variable "project_name" { type = string }
variable "domain_name" { type = string }
variable "cdn_domain" { type = string }
variable "price_class" { type = string }
variable "enable_ipv6" { type = bool }
variable "tahs" {
    type = map(string)
    default = {}
}