provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "BibScrip"
      ManagedBy   = "Terraform"
    }
  }
}

# Separate provider for CloudFront and ACM (must be in us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "BibScrip"
      ManagedBy   = "Terraform"
    }
  }
}
