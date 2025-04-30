# lambda.tf

# Use archive_file data source to create the Lambda deployment package
data "archive_file" "proxy_lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-function"
  output_path = "${path.module}/lambda-function/proxy-lambda.zip"
  excludes    = ["proxy-lambda.zip", "package.sh"]  # Exclude the package script and any existing zip
}

# Create a security group for Lambda
resource "aws_security_group" "lambda_sg" {
  name        = "${var.function_name}-sg"
  description = "Security group for Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.function_name}-sg"
  }
}

# Create the IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach VPC access policy
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Create the Lambda function
resource "aws_lambda_function" "proxy_lambda" {
  function_name    = var.function_name
  description      = "Lambda function to proxy requests to restricted servers"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = var.runtime
  filename         = data.archive_file.proxy_lambda_package.output_path
  source_code_hash = data.archive_file.proxy_lambda_package.output_base64sha256
  memory_size      = var.memory_size
  timeout          = var.timeout

  # VPC configuration
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  # Environment variables
  environment {
    variables = merge(
      {
        ENVIRONMENT = var.environment
      },
      var.environment_variables
    )
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc_access
  ]
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
}