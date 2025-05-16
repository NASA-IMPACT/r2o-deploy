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
    project_name  = optional(string)
    repo_url      = string
    target_path   = string
    target_branch = string
    private       = optional(bool)
  }))
  description = "List of ArgoCD applications to create"
  default     = [
    {
      app_name      = "nginx-app"
      repo_url      = "https://github.com/NASA-IMPACT/r2o-fastapi-k8s"
      target_path   = "fastapi-manifest"
      target_branch = "use-ssl"
      private       = true
    }
  ]
}

variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
}

variable "path_to_github_app_private_key" {
  description = "Path to the GitHub App Private Key"
  type        = string
}

variable "prefix" {
  type = string
}

variable "kind_experimental_provider" {
  type    = string
  default = "podman"
}
