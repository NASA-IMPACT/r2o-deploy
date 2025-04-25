locals {
  # Read the private key from a file if a path is provided
  github_app_private_key = var.github_app_private_key_path != "" ? file(var.github_app_private_key_path) : var.github_app_private_key

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

  # Create sanitized repository names that comply with RFC 1123 (lowercase alphanumeric + dots and dashes)
  sanitized_repos = {
    for app in local.combined_applications :
    app.repo_url => replace(
      lower(
        replace(
          replace(
            replace(app.repo_url, "https://", ""),
            ".git", ""
          ),
          "/", "-"
        )
      ),
      ".", "-"  # Replace dots with dashes to be safe
    )
  }

  # Create repositories configuration with sanitized keys
  repositories_config = var.github_app_id != "" ? {
    configs = {
      repositories = {
        for app in local.combined_applications :
        "repo-${local.sanitized_repos[app.repo_url]}" => {
          url                     = app.repo_url
          type                    = "git"
          name                    = basename(replace(app.repo_url, ".git", ""))
          githubAppID             = var.github_app_id
          githubAppInstallationID = var.github_app_installation_id
          githubAppPrivateKey     = local.github_app_private_key
        }
      }
    }
  } : {}
  
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

# Load the base values.yaml file
data "local_file" "argocd_base_values" {
  filename = "${path.root}/argocd/argocd-conf/values.yaml"
}

# Create the final values.yaml with both base values and dynamic repository config
resource "local_file" "argocd_values" {
  filename = "${path.root}/argocd/argocd-conf/generated-values.yaml"
  content  = "${data.local_file.argocd_base_values.content}\n${yamlencode(local.repositories_config)}"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  values           = [local_file.argocd_values.content]
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