variable "cluster_name" {
  description = "Name of the kind cluster"
  type        = string
  default     = "amarouane"

}


variable "http_ingress_port" {
  type    = number
  default = 8080
}

variable "https_ingress_port" {
  type    = number
  default = 4443
}

variable "app_name" {
  type        = string
  description = "github Application Name"
  default     = "nginx-app"
}

variable "project_name" {
  type        = string
  description = "ArgoCD Project Name"
  default     = "amarouane"
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
