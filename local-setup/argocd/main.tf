locals {
  github_app_private_key = file(var.github_app_private_key_path)
  all_applications       = join("\n---\n", [
    for app in var.argocd_applications : templatefile("${path.root}/argocd/argocd-conf/argocd-github-app.yaml.tmpl", {
      app_name      = app.app_name
      project_name  = coalesce(app.project_name, "default")
      repo_url      = app.repo_url
      target_branch = app.target_branch
      target_path   = app.target_path
    })
  ])
}

resource "local_file" "argocd_values" {
  filename = "${path.root}/argocd/argocd-conf/values.yaml"
  content  = templatefile("${path.root}/argocd/argocd-conf/values.yaml.tmpl", {
    argocd_applications        = var.argocd_applications
    github_app_id              = var.github_app_id
    github_app_installation_id = var.github_app_installation_id
    github_app_private_key     = local.github_app_private_key
  })
}

# Create a single file containing all applications
resource "local_file" "all_argocd_applications" {
  depends_on = [local_file.argocd_values]
  filename   = "${path.root}/argocd/argocd-conf/argocd-github-app.yaml"
  content    = local.all_applications
}

resource "null_resource" "argocd-github-conf" {
  depends_on = [null_resource.argocd-ingess, local_file.all_argocd_applications]
  triggers   = {
    config_hash = sha256(local.all_applications)
  }
  provisioner "local-exec" {
    working_dir = "./argocd"
    command     = "kubectl apply -f ./argocd-conf/argocd-github-app.yaml"
  }
}


resource "helm_release" "argocd" {
  name             = "argocd-helm"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  values           = [local_file.argocd_values.content]
  timeout          = 1500 # Increase timeout to 1 hour
  depends_on       = [local_file.argocd_values]
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
