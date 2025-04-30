# main.tf
locals {
  # Determine if we're using an existing VPC or creating a new one
  vpc_id           = var.create_vpc ? module.vpc.vpc_id : var.existing_vpc_id
  private_subnets  = var.create_vpc ? module.vpc.private_subnet_ids : var.existing_private_subnet_ids
  
  # Lambda environment variables
  lambda_env_vars = merge(
    var.lambda_environment_variables,
    {
      TARGET_SERVERS = join(",", var.target_servers)
    }
  )
}

# Create VPC (if specified)
module "vpc" {
  source = "./vpc"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  aws_region         = var.aws_region
  create_vpc         = var.create_vpc
}

# Create Lambda function
module "lambda" {
  source = "./lambda"

  function_name         = var.lambda_function_name
  runtime               = var.lambda_runtime
  memory_size           = var.lambda_memory_size
  timeout               = var.lambda_timeout
  environment_variables = local.lambda_env_vars
  environment           = var.environment
  
  # VPC configuration
  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets
}