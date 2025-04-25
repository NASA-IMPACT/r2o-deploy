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
  default     = []
}

variable "github_app_id" {
  type        = string
  description = "GitHub App ID used for repository access"
  default     = ""
}

variable "github_app_installation_id" {
  type        = string
  description = "GitHub App Installation ID used for repository access"
  default     = ""
}

variable "github_app_private_key" {
  type        = string
  description = "GitHub App Private Key used for repository access"
  default     = ""
  sensitive   = true
}

variable "github_app_private_key_path" {
  type        = string
  description = "Path to GitHub App Private Key file"
  default     = ""
}