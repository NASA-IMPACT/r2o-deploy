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
  default     = []
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
  default = "/home/opkind/ssl_certs/neo.nsstc.uah.edu.unencrypted.key"
}
variable "ssl_certificate_path" {
  default = "/home/opkind/ssl_certs/bundle-cert-intermediates-root.cer"
}
