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
  default        = "1226282"
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
  default        = "65085904"
}

variable "path_to_github_app_private_key" {
  description = "Path to the GitHub App Private Key"
  type        = string
  default = "/home/ec2-user/.ssh/github-app-key.pem"
}