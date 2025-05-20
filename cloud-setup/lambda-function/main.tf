# Create Lambda deployment package
# this can moved to lambda.tf
data "archive_file" "proxy_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/index.js"
  output_path = "/tmp/proxy-lambda.zip"
}

# Security Group for Lambda
# This can be moved to sg.tf

resource "aws_security_group" "lambda_sg" {
  name        = "${var.prefix}-${var.lambda_function_name}-sg"
  description = "Security group for Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-${var.lambda_function_name}-sg"
  }
}

# IAM Role for Lambda
# This can be moved to iam.tf

resource "aws_iam_role" "lambda_role" {
  name                 = "${var.prefix}-${var.lambda_function_name}-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy Attachments
# These can be moved to iam.tf
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda Function
# This can be moved to lambda.tf
resource "aws_lambda_function" "proxy_lambda" {
  function_name    = "${var.prefix}-${var.lambda_function_name}"
  description      = "Lambda function to proxy requests to restricted servers"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  filename         = data.archive_file.proxy_lambda_package.output_path
  source_code_hash = data.archive_file.proxy_lambda_package.output_base64sha256
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  # VPC configuration - using VPC from remote state
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # Environment variables
  environment {
    variables = var.lambda_environment_variables
  }


}

# CloudWatch Log Group for Lambda
# This can be moved to logs.tf
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.prefix}-${var.lambda_function_name}"
  retention_in_days = 14
}
