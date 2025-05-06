# Data source to read the VPC remote state
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "r2o-tf-state-bucket"
    key    = "vpc/terraform.tfstate"
    region = var.aws_region
  }
}

# Local values 
locals {
  # Always reference the remote VPC state
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  
  lambda_env_vars = {
    ENVIRONMENT   = var.environment
    TARGET_SERVER = var.target_server
  }
}

# Lambda Module
module "lambda" {
  source = "./app"
  
  aws_region           = var.aws_region
  environment          = var.environment
  lambda_function_name = var.lambda_function_name
  lambda_runtime       = var.lambda_runtime
  lambda_memory_size   = var.lambda_memory_size
  lambda_timeout       = var.lambda_timeout
  lambda_environment_variables = local.lambda_env_vars
  
  # Reference VPC state via S3 backend
  vpc_state_bucket = "r2o-tf-state-bucket"
  vpc_state_key    = "vpc/terraform.tfstate"
}