output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.lambda_function_arn
}

output "lambda_invoke_arn" {
  description = "Invocation ARN of the Lambda function"
  value       = module.lambda.lambda_invoke_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.lambda.lambda_role_arn
}

output "vpc_id" {
  description = "ID of the VPC (created or existing)"
  value       = local.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (created or existing)"
  value       = local.private_subnets
}
