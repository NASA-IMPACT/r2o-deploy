resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  values           = [file("${path.root}/argocd/argocd-conf/values.yaml")]
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


resource "local_file" "argocd-github-conf-template" {

  content = templatefile("${path.root}/argocd/argocd-conf/argocd-github-app.yaml.tmpl",
    {
      app_name      = var.app_name
      project_name  = var.project_name
      repo_url      = var.repo_url
      target_path   = var.target_path
      target_branch = var.target_branch

    }


  )
  filename = "${path.root}/argocd/argocd-conf/argocd-github-app.yaml"
}

resource "null_resource" "argocd-github-conf" {
  depends_on = [null_resource.argocd-ingess, local_file.argocd-github-conf-template]
  triggers = {
    config_hash = sha256(file("${path.root}/argocd/argocd-conf/argocd-github-app.yaml.tmpl"))


  }
  provisioner "local-exec" {
    working_dir = "./argocd"
    command     = "kubectl apply -f ./argocd-conf/argocd-github-app.yaml"
  }
}
