provider "aws" {
  region = var.aws_region

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

  # Remove this block:
  # backend "s3" {}
}
