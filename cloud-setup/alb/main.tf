



locals {
  subdomain           = var.subdomain == "null" ? var.prefix : var.subdomain
}
resource "aws_alb" "r2o_proxy" {
  name            = "${var.prefix}-proxy"
  internal        = false
  security_groups = [aws_security_group.r2o_proxy_alb.id]
  subnets         = var.public_subnet_ids
  tags = {
    Contact = var.contact
    Project = var.project
  }
}


resource "aws_route53_record" "lambda-alb-record" {
  name    = "${lower(local.subdomain)}.${var.proxy_domain_name}"
  type    = "A"
  zone_id = data.aws_route53_zone.lambda_domain.zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_alb.r2o_proxy.dns_name
    zone_id                = aws_alb.r2o_proxy.zone_id
  }
}

resource "aws_alb_target_group" "lambda-default-target-grp" {
  name        = "${var.prefix}-lambda-tg"
  target_type = "lambda"
  tags = {
    Contact = var.contact
    Project = var.project
  }
}



resource "aws_alb_listener" "lambda-alb-https" {
  load_balancer_arn = aws_alb.r2o_proxy.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.lambda-domain-certificate.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.lambda-default-target-grp.arn
  }

  depends_on = [aws_alb_target_group.lambda-default-target-grp]
}

resource "aws_alb_listener" "lambda-alb-http-to-https" {
  load_balancer_arn = aws_alb.r2o_proxy.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  depends_on = [aws_alb_target_group.lambda-default-target-grp]
}

resource "aws_alb_target_group" "lambda-app-target-group" {
  name        = "${var.prefix}-lambda-app-tg"
  target_type = "lambda"
  health_check {
    enabled = true
    path    = "/health"
    # Lambda health checks use different settings
    interval            = 35
    timeout             = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Contact = var.contact
    Project = var.project
  }
}

resource "aws_alb_listener_rule" "lambda-alb-listener-role" {
  listener_arn = aws_alb_listener.lambda-alb-https.arn
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.lambda-app-target-group.arn
  }
  condition {
    host_header {
      values = ["${lower(local.subdomain)}.${var.proxy_domain_name}"]
    }
  }
}


resource "aws_alb_target_group_attachment" "lambda-app-attachment" {
  target_group_arn = aws_alb_target_group.lambda-app-target-group.arn
  target_id        = var.lambda_function_arn
  depends_on       = [aws_lambda_permission.allow_alb]
}

# Permission for ALB to invoke Lambda

resource "aws_lambda_permission" "allow_alb" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_alb_target_group.lambda-app-target-group.arn
}


resource "aws_security_group" "r2o_proxy_alb" {
  name_prefix = "${var.prefix}-webserver-alb-"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}