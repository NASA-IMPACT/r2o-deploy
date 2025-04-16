module "kind" {
  source             = "./kind"
  cluster_name       = var.cluster_name
  http_ingress_port  = var.http_ingress_port
  https_ingress_port = var.https_ingress_port
}

module "argocd" {
  source              = "./argocd"
  depends_on          = [module.kind]
  argocd_applications = local.argocd_applications
}


