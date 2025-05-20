variable "prefix" {
  type = string

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
