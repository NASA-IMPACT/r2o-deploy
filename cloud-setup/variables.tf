variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2"
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

variable "lambda_timeout_in_minutes" {
  description = "Timeout for the Lambda function in minutes"
  type        = number
  default     = 5
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


variable "fm_api_key" {
  type = string
  description = "API key for the FM service"
}

variable "public_subnets_tagname" {
  type = string
  default = "*public-subnet-*"
}

variable "subdomain" {
  default = "dev"
}
variable "proxy_domain_name" {
  default = "fm.dsig.net"
}
