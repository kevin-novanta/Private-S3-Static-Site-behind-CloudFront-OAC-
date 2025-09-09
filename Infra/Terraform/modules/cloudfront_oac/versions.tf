terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # The module expects an aliased provider for us-east-1 (for ACM)
      configuration_aliases = [aws.us_east_1]
    }
  }
}