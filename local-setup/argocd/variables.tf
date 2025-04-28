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