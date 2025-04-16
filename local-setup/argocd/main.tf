resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  values           = [file("${path.root}/argocd/argocd-conf/values.yaml")]
  timeout = 1200 # Increase timeout to 1one hour
}

resource "null_resource" "password" {
  depends_on = [helm_release.argocd]
  provisioner "local-exec" {
    working_dir = "./argocd"
    command     = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath={.data.password} | base64 -d > argocd-login.txt"
  }
}

resource "null_resource" "argocd-ingess" {
  depends_on = [helm_release.argocd, helm_release.argocd]
  provisioner "local-exec" {
    working_dir = "./argocd"
    command     = "kubectl apply -f ./argocd-conf/argocd-ingress.yaml"
  }
}


resource "local_file" "argocd-github-conf-templates" {
  for_each = { for idx, app in var.argocd_applications : app.app_name => app }
  
  content = templatefile("${path.root}/argocd/argocd-conf/argocd-github-app.yaml.tmpl",
    {
      app_name      = each.value.app_name
      project_name  = each.value.project_name
      repo_url      = each.value.repo_url
      target_path   = each.value.target_path
      target_branch = each.value.target_branch
      namespace     = lookup(each.value, "namespace", "default")
    }
  )
  filename = "${path.root}/argocd/argocd-conf/argocd-${each.value.app_name}-app.yaml"
}

resource "null_resource" "argocd-github-conf" {
  for_each = { for idx, app in var.argocd_applications : app.app_name => app }
  
  depends_on = [null_resource.argocd-ingess, local_file.argocd-github-conf-templates]
  
  triggers = {
    config_hash = sha256(jsonencode(each.value))
  }
  
  provisioner "local-exec" {
    working_dir = "./argocd"
    command     = "kubectl apply -f ./argocd-conf/argocd-${each.value.app_name}-app.yaml"
  }
}
