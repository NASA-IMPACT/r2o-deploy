resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  values           = [file("${path.root}/argocd/argocd-conf/values.yaml")]
  timeout          = 1200 # Increase timeout to 1 hour
}

resource "null_resource" "password" {
  depends_on = [helm_release.argocd]
  provisioner "local-exec" {
    working_dir = "./argocd"
    command     = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath={.data.password} | base64 -d > argocd-login.txt"
  }
}

resource "null_resource" "argocd-ingess" {
  depends_on = [helm_release.argocd]
  provisioner "local-exec" {
    working_dir = "./argocd"
    command     = "sleep 30 && kubectl apply -f ./argocd-conf/argocd-ingress.yaml"
  }
}

locals {
  # Combine the default application with the list of additional applications
  combined_applications = concat(
    length(var.argocd_applications) > 0 ? var.argocd_applications : [{
      app_name      = var.app_name
      project_name  = var.project_name
      repo_url      = var.repo_url
      target_path   = var.target_path
      target_branch = var.target_branch
      namespace     = "default"
    }]
  )

  all_applications = join("\n---\n", [
    for app in local.combined_applications : templatefile("${path.root}/argocd/argocd-conf/argocd-github-app.yaml.tmpl", {
      app_name      = app.app_name
      project_name  = app.project_name
      repo_url      = app.repo_url
      target_branch = app.target_branch
      target_path   = app.target_path
    })
  ])
}

# Create a single file containing all applications
resource "local_file" "all_argocd_applications" {
  filename = "${path.root}/argocd/argocd-conf/all-applications.yaml"
  content  = local.all_applications
}

resource "null_resource" "argocd-github-conf" {
  depends_on = [null_resource.argocd-ingess, local_file.all_argocd_applications]
  triggers = {
    config_hash = sha256(local.all_applications)
  }
  provisioner "local-exec" {
    working_dir = "./argocd"
    command     = "kubectl apply -f ./argocd-conf/all-applications.yaml"
  }
}