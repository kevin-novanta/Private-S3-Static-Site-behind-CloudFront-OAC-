terraform {
  backend "s3" {
    # One-time created state bucket (must already exist)
    bucket         = "p1-tfstate-207567803283"
    key            = "private-s3-oac/staging/terraform.tfstate"
    region         = "us-east-1"

    # Good hygiene
    encrypt        = true
    dynamodb_table = "p1-terraform-locks"  # for state locking
  }
}