provider "aws" {
  region = var.aws_region

  # Optional settings for assuming roles or other provider-level configurations
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "proxy-lambda"
      ManagedBy   = "opentofu"
    }
  }
}

# AWS Provider version constraints
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}