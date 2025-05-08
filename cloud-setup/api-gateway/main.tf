# Create the API Gateway REST API
resource "aws_api_gateway_rest_api" "proxy_api" {
  name        = var.api_name
  description = "API Gateway for proxy Lambda function"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Create a resource that matches any path
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.proxy_api.id
  parent_id   = aws_api_gateway_rest_api.proxy_api.root_resource_id
  path_part   = "{proxy+}"
}

# ANY method for the proxy resource
resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.proxy_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"  # Changed from authorization_type
}

# Integration with Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.proxy_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Root resource - ANY method
resource "aws_api_gateway_method" "root_any" {
  rest_api_id   = aws_api_gateway_rest_api.proxy_api.id
  resource_id   = aws_api_gateway_rest_api.proxy_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"  # Changed from authorization_type
}

# Root resource - Lambda integration
resource "aws_api_gateway_integration" "root_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.proxy_api.id
  resource_id             = aws_api_gateway_rest_api.proxy_api.root_resource_id
  http_method             = aws_api_gateway_method.root_any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Deployment for the API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.root_lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.proxy_api.id
  
  # Force a new deployment when configurations change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_any.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_method.root_any.id,
      aws_api_gateway_integration.root_lambda_integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Stage for the deployment
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.proxy_api.id
  stage_name    = var.environment
}

# Method Settings to control throttling (add this)
resource "aws_api_gateway_method_settings" "settings" {
  rest_api_id = aws_api_gateway_rest_api.proxy_api.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "*/*"  # This applies to all methods

  settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}

# Lambda permission to allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  
  # Allow invocation from any stage/path
  source_arn = "${aws_api_gateway_rest_api.proxy_api.execution_arn}/*/*"
}