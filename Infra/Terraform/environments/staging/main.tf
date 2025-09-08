module "static_site" {
    source = "../../modules/cloudfront_oac"
    projet_name = var.project_name
    domain_name = var.domain_name
    cdn_domain = var.cdn_domain
    price_class = var.price_class
    enable_ipv6 = var.enable_ipv6

    tags = {
        environment = "staging"
    }

    providers = {
        aws.us_east_1 = aws.us_east_1
    }
}