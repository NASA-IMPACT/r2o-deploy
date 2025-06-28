module "kind" {
  source                     = "./kind"
  cluster_name               = var.cluster_name
  http_ingress_port          = var.http_ingress_port
  https_ingress_port         = var.https_ingress_port
  cluster_executable         = var.cluster_executable
  ssl_private_key_path = var.ssl_private_key_path
  ssl_certificate_path = var.ssl_certificate_path
}


module "argocd" {
  source                      = "./argocd"
  depends_on                  = [module.kind]
  argocd_applications         = var.argocd_applications
  github_app_private_key_path = var.github_app_private_key_path
  github_app_id               = var.github_app_id
  github_app_installation_id  = var.github_app_installation_id
  domain_name = var.domain_name
  ssl_private_key_path = var.ssl_private_key_path
  ssl_certificate_path = var.ssl_certificate_path
}


