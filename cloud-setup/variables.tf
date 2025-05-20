variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2"
}


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
  default     = "https://kind.neo.nsstc.uah.edu:4449"
}

variable "prefix" {
  type = string
}

variable "permissions_boundary" {
  default = "arn:aws:iam::244822573120:policy/permission_boundaries"
}

variable "vpc_id" {
  default = "vpc-096befd8a22b647c3"
}

variable "private_subnets_tagname" {
  default = "*private-subnet-*"
}

variable "api_name" {
  default = "proxy-api"
}
