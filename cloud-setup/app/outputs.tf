output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.proxy_lambda.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.proxy_lambda.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_invoke_arn" {
  description = "Invocation ARN of the Lambda function"
  value       = aws_lambda_function.proxy_lambda.invoke_arn
}

output "lambda_security_group_id" {
  description = "ID of the Lambda security group"
  value       = aws_security_group.lambda_sg.id
}

output "lambda_log_group_name" {
  description = "Name of the Lambda CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}