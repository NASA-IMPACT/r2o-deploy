resource "local_file" "argocd_values" {
  filename = "${path.root}/argocd/argocd-conf/values.yaml"
  content = templatefile("${path.root}/argocd/argocd-conf/values.yaml.tmpl", {
    argocd_applications = var.argocd_applications
    github_app_id = var.github_app_id
    github_app_installation_id = var.github_app_installation_id
    github_app_private_key = var.github_app_private_key
  })
}


resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  values           = [local_file.argocd_values.content]
  timeout          = 1200 # Increase timeout to 1 hour
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
