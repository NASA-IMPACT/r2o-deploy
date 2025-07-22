
locals {
  argocd_applications = [
    {
      app_name      = "fastapi-app"
      project_name  = null
      repo_url      = "https://github.com/NASA-IMPACT/r2o-fastapi-k8s"
      target_path   = "fastapi-manifest"
      target_branch = var.fastapi_branch
      private       = true
    },
    {
      app_name      = "nginx-app"
      project_name  = null
      repo_url      = "https://github.com/amarouane-ABDELHAK/eks-apps"
      target_path   = "app/nginx_app"
      target_branch = "use-ssl"
      private       = false
    },
    {
      app_name      = "predictor-app"
      project_name  = null
      repo_url      = "https://github.com/NASA-IMPACT/fm-inference-sagemaker"
      target_path   = "mvp"
      target_branch = var.prediction_branch
      private       = true
    }
  ]
}
