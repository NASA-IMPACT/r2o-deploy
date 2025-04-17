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
