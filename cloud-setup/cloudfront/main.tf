provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "cloudfront-distribution"
      ManagedBy   = "opentofu"
    }
  }
}

# Remove this terraform block if it exists
# terraform {
#   backend "s3" {}
# }

# Remove this remote state data source
# data "terraform_remote_state" "api_gateway" {
#   backend = "s3"
#   config = {
#     bucket = var.state_bucket
#     key    = var.api_gateway_state_key
#     region = var.aws_region
#   }
# }

# CloudFront distribution
resource "aws_cloudfront_distribution" "api_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.environment}-api-distribution"
  default_root_object = ""
  price_class         = "PriceClass_100"

  # Use directly passed domain instead of remote state
  origin {
    domain_name = var.api_gateway_domain
    origin_id   = var.origin_id
    
    # Add origin path to point to the stage
    origin_path = "/dev"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.origin_id

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["*"]
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.environment}-api-distribution"
  }
}