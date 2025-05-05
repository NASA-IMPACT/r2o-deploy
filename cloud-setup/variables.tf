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

# variable "create_vpc" {
#   description = "Whether to create a new VPC or use an existing one"
#   type        = bool
#   default     = true
# }

# variable "existing_vpc_id" {
#   description = "ID of an existing VPC to use if create_vpc is false"
#   type        = string
#   default     = ""
# }

# variable "existing_private_subnet_ids" {
#   description = "List of existing private subnet IDs to use if create_vpc is false"
#   type        = list(string)
#   default     = []
# }

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to deploy resources in"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "proxy-lambda"
}

variable "lambda_runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_memory_size" {
  description = "Memory size for the Lambda function in MB"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 30
}

variable "lambda_environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "target_server" {
  description = "Target server to proxy to"
  type        = string
  default     = "http:///35.163.154.91:9999"
}