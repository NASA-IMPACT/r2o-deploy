module "kind" {
  source             = "./kind"
  cluster_name       = var.cluster_name
  http_ingress_port  = var.http_ingress_port
  https_ingress_port = var.https_ingress_port
}


module "argocd" {
  source        = "./argocd"
  depends_on    = [module.kind]
  app_name      = var.app_name
  project_name  = var.project_name
  repo_url      = var.repo_url
  target_path   = var.target_path
  target_branch = var.target_branch


}


