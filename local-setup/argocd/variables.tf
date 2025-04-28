variable "argocd_applications" {
  type = list(object({
    app_name      = string
    project_name  = string
    repo_url      = string
    target_path   = string
    target_branch = string
    private       = optional(bool, false)
    namespace     = optional(string, "default")
  }))
  description = "List of ArgoCD applications to create"
  default = []
}


variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
}

variable "github_app_private_key" {
  description = "GitHub App Private Key"
  type        = string
}


