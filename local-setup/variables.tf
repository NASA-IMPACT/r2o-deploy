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

variable "app_name" {
  type        = string
  description = "github Application Name"
  default     = "nginx-app"
}

variable "project_name" {
  type        = string
  description = "ArgoCD Project Name"
  default     = "default"
}

variable "target_branch" {
  type        = string
  description = "Target Branch Name"
  default     = "main"
}

variable "repo_url" {
  type        = string
  description = "Repo URL"
  default     = "https://github.com/amarouane-ABDELHAK/eks-apps"
}
variable "target_path" {
  type        = string
  description = "Target app"
  default     = "app/nginx_app"
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
  },
  
  {
    app_name      = "nginx-apxscscp"
    project_name  = "default"
    repo_url      = "https://github.com/amarouane-ABDELHAK/cscscsc"
    target_path   = "app/cscscsc"
    target_branch = "cscsc"
    namespace     = "decscscfault"
  }
  
  ]
}