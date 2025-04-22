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
  default = []
}

variable "app_name" {
  type        = string
  description = "github Application Name"
}

variable "project_name" {
  type        = string
  description = "ArgoCD Project Name"
}

variable "target_branch" {
  type        = string
  description = "Target Branch Name"
}

variable "repo_url" {
  type        = string
  description = "Repo URL"
}
variable "target_path" {
  type        = string
  description = "Repo target path"
}

