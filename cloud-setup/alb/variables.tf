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

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "lambda-alb"
}

variable "vpc_state_bucket" {
  description = "S3 bucket containing the VPC state file"
  type        = string
  default     = "r2o-tf-state-bucket"
}

variable "vpc_state_key" {
  description = "Key of the VPC state file in the S3 bucket"
  type        = string
  default     = "vpc/terraform.tfstate"
}

variable "lambda_state_bucket" {
  description = "S3 bucket containing the Lambda state file"
  type        = string
  default     = "r2o-tf-state-bucket"
}

variable "lambda_state_key" {
  description = "Key of the Lambda state file in the S3 bucket"
  type        = string
  default     = "app/terraform.tfstate"
}

variable "enable_https" {
  description = "Whether to enable HTTPS listener"
  type        = bool
  default     = false
}

variable "enable_https_redirect" {
  description = "Whether to redirect HTTP to HTTPS"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Path for ALB health checks"
  type        = string
  default     = "/"
}