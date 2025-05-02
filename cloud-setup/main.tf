# This should deploy app as well from the cloud-setup directory

# Data source to get the existing VPC if we're not creating one
data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  id    = var.existing_vpc_id
}

# Data source to get existing private subnets if we're not creating a VPC
data "aws_subnet" "existing_private" {
  count = var.create_vpc ? 0 : length(var.existing_private_subnet_ids)
  id    = var.existing_private_subnet_ids[count.index]
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