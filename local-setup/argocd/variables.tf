variable "argocd_applications" {
  type = list(object({
    app_name      = string
    project_name  = string
    repo_url      = string
    target_path   = string
    target_branch = string
    private       = optional(bool)
  }))
  description = "List of ArgoCD applications to create"
}


variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
}

variable "github_app_private_key_path" {
  description = "Path to the GitHub App Private Key"
  type        = string
}
variable "ssl_private_key_path" {
}
variable "ssl_certificate_path" {
}

variable "domain_name" {
  type = string
  
}
