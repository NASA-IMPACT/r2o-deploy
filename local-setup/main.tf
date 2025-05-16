#module "kind" {
#  source                     = "./kind"
#  cluster_name               = var.cluster_name
#  http_ingress_port          = var.http_ingress_port
#  https_ingress_port         = var.https_ingress_port
#  kind_experimental_provider = var.kind_experimental_provider
#}


module "argocd" {
  source                      = "./argocd"
  depends_on                  = [module.kind]
  argocd_applications         = var.argocd_applications
  github_app_private_key_path = var.path_to_github_app_private_key
  github_app_id               = var.github_app_id
  github_app_installation_id  = var.github_app_installation_id
}


