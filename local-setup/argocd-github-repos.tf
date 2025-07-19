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
      app_name      = "fastapi-app"
      repo_url      = "https://github.com/NASA-IMPACT/r2o-fastapi-k8s"
      target_path   = "fastapi-manifest"
      target_branch = "use-ssl"
      private       = true
    },
    {
      app_name      = "nginx-app"
      repo_url      = "https://github.com/amarouane-ABDELHAK/eks-apps"
      target_path   = "app/nginx_app"
      target_branch = "use-ssl"
      private       = false
    },
    {
      app_name      = "predictor-app"
      repo_url      = "https://github.com/NASA-IMPACT/fm-inference-sagemaker"
      target_path   = "k8s-manifests"
      target_branch = "feature/add-k8s-services"
      private       = true
    },

  ]
}
