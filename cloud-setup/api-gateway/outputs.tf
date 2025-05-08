output "api_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.proxy_api.id
}

output "api_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.dev.stage_name
}

output "invoke_url" {
  description = "URL to invoke the API Gateway"
  value       = aws_api_gateway_stage.dev.invoke_url
}

output "execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.proxy_api.execution_arn
}