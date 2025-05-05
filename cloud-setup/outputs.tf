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

# ALB outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "alb_http_url" {
  description = "HTTP URL of the Application Load Balancer"
  value       = "http://${module.alb.alb_dns_name}"
}

output "alb_https_url" {
  description = "HTTPS URL of the Application Load Balancer (if HTTPS is enabled)"
  value       = var.enable_https ? "https://${module.alb.alb_dns_name}" : null
}