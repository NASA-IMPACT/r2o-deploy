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

# API Gateway outputs
output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = module.api_gateway.api_id
}

output "api_gateway_invoke_url" {
  description = "URL to invoke the API Gateway"
  value       = module.api_gateway.invoke_url
}

output "api_gateway_stage" {
  description = "Stage name of the API Gateway"
  value       = module.api_gateway.api_stage_name
}

# CloudFront outputs
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_domain_name
}
