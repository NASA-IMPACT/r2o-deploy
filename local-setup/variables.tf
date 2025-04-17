variable "cluster_name" {
  description = "Name of the kind cluster"
  type        = string
}

variable "http_ingress_port" {
  type    = number
  default = 8888
}

variable "https_ingress_port" {
  type    = number
  default = 4444
}

variable "argocd_applications" {
  type = list(object({
    app_name      = string
    project_name  = string
    repo_url      = string
    target_path   = string
    target_branch = string
    namespace     = optional(string, "default")
  }))
  description = "List of ArgoCD applications to create"
  default = [{
    app_name      = "nginx-app"
    project_name  = "default"
    repo_url      = "https://github.com/amarouane-ABDELHAK/eks-apps"
    target_path   = "app/nginx_app"
    target_branch = "main"
    namespace     = "default"
  }]
}

