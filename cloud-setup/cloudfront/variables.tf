variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "origin_id" {
  description = "Origin ID for CloudFront distribution"
  type        = string
}

# New variable to replace remote state reference
variable "api_gateway_domain" {
  description = "Domain of the API Gateway for CloudFront origin"
  type        = string
}

# You can remove these variables if they're no longer used
# variable "state_bucket" {
#   description = "S3 bucket containing the state files"
#   type        = string
# }

# variable "api_gateway_state_key" {
#   description = "Key of the API Gateway state file in the S3 bucket"
#   type        = string
# }