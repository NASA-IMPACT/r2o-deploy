variable "lambda_runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  #  default     = "nodejs18.x"
}

variable "lambda_memory_size" {
  description = "Memory size for the Lambda function in MB"
  type        = number
  #  default     = 128
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  #  default     = 30
}

variable "lambda_environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  #  default     = {}
}


variable "prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "lambda_function_name" {
  type = string
}

variable "permissions_boundary" {
  type = string
}
