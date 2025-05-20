provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "R2O-${var.prefix}"
      ManagedBy = "opentofu"
    }
  }
}

# Add this provider specifically for CloudFront WAF
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project   = "R2O-${var.prefix}"
      ManagedBy = "opentofu"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
  
}
