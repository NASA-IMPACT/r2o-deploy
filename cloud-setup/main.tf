# Local values
locals {
  lambda_env_vars = {
    TARGET_SERVER = var.target_server
  }
}

# Lambda Module



data "aws_subnets" "private_subnets_id" {
  filter {
    name   = "tag:Name"
    values = [var.private_subnets_tagname]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

}



module "lambda" {
  source                       = "./lambda-function"
  lambda_environment_variables = local.lambda_env_vars
  lambda_function_name         = var.lambda_function_name
  lambda_memory_size           = var.lambda_memory_size
  lambda_runtime               = var.lambda_runtime
  lambda_timeout               = var.lambda_timeout
  permissions_boundary         = var.permissions_boundary
  prefix                       = var.prefix
  private_subnet_ids           = data.aws_subnets.private_subnets_id.ids
  vpc_id                       = var.vpc_id
}

# API Gateway Module

module "api_gateway" {
  source = "./api-gateway"

  aws_region           = var.aws_region
  api_name             = var.api_name
  lambda_function_name = module.lambda.lambda_function_name
  lambda_invoke_arn    = module.lambda.lambda_invoke_arn
  prefix               = var.prefix
}

# CloudFront Module - Updated to use direct outputs
module "cloudfront" {
  source             = "./cloudfront"
  prefix             = var.prefix
  origin_id          = "proxy-rest-api"
  # Fix the domain format - extract only the hostname part without protocol and path
  api_gateway_domain = replace(
    replace(module.api_gateway.invoke_url, "/^https?:\\/\\//", ""),
    "/\\/.*$/", ""
  )
}
