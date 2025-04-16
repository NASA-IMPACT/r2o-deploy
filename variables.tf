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

variable "argocd_apps_file" {
  type        = string
  description = "Path to JSON file containing ArgoCD applications configuration"
  default     = "argocd-apps.json"
}

# Add a local variable to handle the JSON file
locals {
  argocd_applications = fileexists(var.argocd_apps_file) ? jsondecode(file(var.argocd_apps_file)) : []
}