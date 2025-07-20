module "kind" {
  source                     = "./kind"
  cluster_name               = var.cluster_name
  http_ingress_port          = var.http_ingress_port
  https_ingress_port         = var.https_ingress_port
  cluster_executable         = var.cluster_executable
  ssl_private_key_path = var.ssl_private_key_path
  ssl_certificate_path = var.ssl_certificate_path
  cloudfront_id      = var.cloudfront_id
  oidc_issuer_url    = var.oidc_issuer_url
  oidc_role_arn      = var.oidc_role_arn
  oidc_s3_bucketname = var.oidc_s3_bucketname
}

# Add module to provision lambda



module "argocd" {
  source                      = "./argocd"
  depends_on                  = [module.kind]
  argocd_applications         = local.argocd_applications
  github_app_private_key_path = var.github_app_private_key_path
  github_app_id               = var.github_app_id
  github_app_installation_id  = var.github_app_installation_id
  domain_name = var.domain_name
  ssl_private_key_path = var.ssl_private_key_path
  ssl_certificate_path = var.ssl_certificate_path
}

module "monitoring" {
  source = "./monitoring"
  depends_on                  = [module.kind]
  ssl_private_key_path = var.ssl_private_key_path
  ssl_certificate_path = var.ssl_certificate_path
  domain_name = var.domain_name
  grafana_admin = var.grafana_admin
  grafana_password = var.grafana_password
}


