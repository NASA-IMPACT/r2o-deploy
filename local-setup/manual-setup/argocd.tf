resource "helm_release" "argocd" {
  depends_on       = [null_resource.setup-kind, local_file.argocd_values]
  name             = "argocd-helm"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  values           = [local_file.argocd_values.content]
  timeout          = 1500 # Increase timeout to 1 hour
}


resource "local_file" "argocd_values" {
  filename = "${path.root}/argocd/argocd-conf/values.yaml"
  content  = templatefile("${path.root}/argocd/argocd-conf/values.yaml.tmpl", {
    argocd_applications        = []
    github_app_id              = ""
    github_app_installation_id = ""
    github_app_private_key     = ""
  })
}
