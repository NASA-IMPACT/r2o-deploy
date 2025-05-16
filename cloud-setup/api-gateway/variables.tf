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

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "rest-proxy"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to integrate with API Gateway"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invocation ARN of the Lambda function"
  type        = string
}