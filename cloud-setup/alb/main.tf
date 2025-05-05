# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # Allow HTTP and HTTPS inbound traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-${var.alb_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  tags = {
    Name = "${var.environment}-${var.alb_name}"
  }
}

# Lambda Target Group
resource "aws_lb_target_group" "lambda" {
  name        = "${var.environment}-lambda-tg"
  target_type = "lambda"
  
  # For Lambda target groups, port, protocol, and VPC are not used
  # but are still required by AWS API
  port        = 443
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  health_check {
    enabled = true
    path     = var.health_check_path
    matcher  = "200"
    interval = 30
    timeout  = 5
  }

  tags = {
    Name = "${var.environment}-lambda-tg"
  }
}

# Register Lambda with Target Group
resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda.arn
  target_id        = data.terraform_remote_state.lambda.outputs.lambda_function_arn
  depends_on       = [aws_lambda_permission.allow_alb]
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.enable_https_redirect ? "redirect" : "forward"
    
    dynamic "redirect" {
      for_each = var.enable_https_redirect ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = var.enable_https_redirect ? [] : [1]
      content {
        target_group {
          arn = aws_lb_target_group.lambda.arn
        }
      }
    }
  }
}

# HTTPS Listener (conditional)
resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda.arn
  }
}

# Permission for ALB to invoke Lambda
resource "aws_lambda_permission" "allow_alb" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = data.terraform_remote_state.lambda.outputs.lambda_function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda.arn
}

# Read VPC outputs from remote state
data "terraform_remote_state" "vpc" {
  backend = "s3"  
  config = {
    bucket = var.vpc_state_bucket
    key    = var.vpc_state_key
    region = var.aws_region
  }
}

# Read Lambda outputs from remote state
data "terraform_remote_state" "lambda" {
  backend = "s3"  
  config = {
    bucket = var.lambda_state_bucket
    key    = var.lambda_state_key
    region = var.aws_region
  }
}