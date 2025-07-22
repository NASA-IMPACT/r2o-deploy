# Local values
locals {
  lambda_env_vars = {
    TARGET_SERVER = var.target_server
    API_KEY = var.fm_api_key

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



module "alb" {
  source = "./alb"
  contact              = "r2o-maintainers"
  lambda_function_name = module.lambda.lambda_function_name
  prefix               = var.prefix
  project              = "Research to Operation"
  public_subnet_ids    = data.aws_subnets.public_subnets_id.ids
  subdomain            = var.subdomain
  vpc_id               = var.vpc_id
  proxy_domain_name = var.proxy_domain_name
  lambda_function_arn = module.lambda.lambda_function_arn
}
