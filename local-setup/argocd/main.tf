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


resource "kubernetes_manifest" "argocd_app" {
  for_each = { for app in var.argocd_applications : app.app_name => app }

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = each.value.app_name
      namespace = "argocd"
    }
    spec = {
      project = each.value.project_name
      source = {
        repoURL        = each.value.repo_url
        targetRevision = each.value.target_branch
        path           = each.value.target_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }
}

resource "kubernetes_secret" "argocd_github_app" {
  metadata {
    name      = "github-app-credentials"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repo"
    }
  }

  type = "Opaque"

  data = {
    url                      = base64encode("https://github.com")
    githubAppID              = base64encode(var.github_app_id)
    githubAppInstallationID = base64encode(var.github_app_installation_id)
    githubAppPrivateKey     = base64encode(var.github_app_private_key)
  }
}




