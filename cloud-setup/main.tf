# Data source to read the VPC remote state
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config  = {
    bucket = "r2o-tf-state-bucket"
    key    = "vpc/terraform.tfstate"
    region = var.aws_region
  }
}

# Local values 
locals {
  # Always reference the remote VPC state
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  lambda_env_vars = {
    ENVIRONMENT   = var.environment
    TARGET_SERVER = var.target_server
  }
}

# Lambda Module
module "lambda" {
  source = "./app"

  aws_region                   = var.aws_region
  environment                  = var.environment
  lambda_function_name         = var.lambda_function_name
  lambda_runtime               = var.lambda_runtime
  lambda_memory_size           = var.lambda_memory_size
  lambda_timeout               = var.lambda_timeout
  lambda_environment_variables = local.lambda_env_vars

  # Reference VPC state via S3 backend
  vpc_state_bucket = "r2o-tf-state-bucket"
  vpc_state_key    = "vpc/terraform.tfstate"
}

# API Gateway Module
module "api_gateway" {
  source = "./api-gateway"

  aws_region           = var.aws_region
  environment          = var.environment
  api_name             = "rest-proxy"
  lambda_function_name = module.lambda.lambda_function_name
  lambda_invoke_arn    = module.lambda.lambda_invoke_arn
  prefix               = var.prefix
}

# CloudFront Module - Updated to use direct outputs
module "cloudfront" {
  source = "./cloudfront"

  aws_region  = var.aws_region
  environment = var.environment
  origin_id   = "r2o-api-tf"

  # Fix the domain format - extract only the hostname part without protocol and path
  api_gateway_domain = replace(
    replace(module.api_gateway.invoke_url, "/^https?:\\/\\//", ""),
    "/\\/.*$/", ""
  )
}
