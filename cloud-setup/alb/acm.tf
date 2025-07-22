resource "aws_acm_certificate" "lambda-domain-certificate" {
  domain_name       = "${lower(local.subdomain)}.${var.proxy_domain_name}"
  validation_method = "DNS"
  tags = {
    Contact = "Abdelhak"
    Project = var.project
  }
}


data "aws_route53_zone" "lambda_domain" {
  name         = var.proxy_domain_name
  private_zone = false
}
resource "aws_route53_record" "ecs_cert_vald_rec" {
  name            = tolist(aws_acm_certificate.lambda-domain-certificate.domain_validation_options)[0].resource_record_name
  type            = tolist(aws_acm_certificate.lambda-domain-certificate.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.lambda_domain.zone_id
  records         = [tolist(aws_acm_certificate.lambda-domain-certificate.domain_validation_options)[0].resource_record_value]
  ttl             = 60
  allow_overwrite = true
}


resource "aws_acm_certificate_validation" "lambda_domain_cert_vals" {
  certificate_arn         = aws_acm_certificate.lambda-domain-certificate.arn
  validation_record_fqdns = [aws_route53_record.ecs_cert_vald_rec.fqdn]
}