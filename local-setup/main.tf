module "manual-setup" {
  count              = var.manual_setup ? 1 : 0
  source             = "./manual-setup"
  cluster_name       = var.cluster_name
  http_ingress_port  = var.http_ingress_port
  https_ingress_port = var.https_ingress_port
}

module "kind" {
  source                     = "./kind"
  count                      = var.manual_setup ? 0 : 1
  cluster_name               = var.cluster_name
  http_ingress_port          = var.http_ingress_port
  https_ingress_port         = var.https_ingress_port
  kind_experimental_provider = var.kind_experimental_provider
  provision_kind_cluster     = var.manual_setup == false
}


module "argocd" {
  source                      = "./argocd"
  count                       = var.manual_setup ? 0 : 1
  depends_on                  = [module.kind]
  argocd_applications         = var.argocd_applications
  github_app_private_key_path = var.path_to_github_app_private_key
  github_app_id               = var.github_app_id
  github_app_installation_id  = var.github_app_installation_id
  provision_argocd            = var.manual_setup == false
}


