variable "subdomain" {
  type = string
}

variable "prefix" {
  type = string
}


variable "proxy_domain_name" {
  type = string
}
variable "public_subnet_ids" {

}
variable "contact" {
  type = string

}
variable "project" {
  type = string
}

variable "lambda_function_name" {
  type = string
}
variable "vpc_id" {
  type = string
}

# Lambda function target group attachment
variable "lambda_function_arn" {
  type = string
}