
resource "helm_release" "kube-prometheus" {
  name       = "prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true
  version    = "45.7.1"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
 values = [
    file("${path.module}/values.yaml")
  ]
}

resource "null_resource" "setup-certificate-secrets" {

  depends_on = [helm_release.kube-prometheus]

  triggers = {
    private_key_hash = sha256(file(var.ssl_private_key_path))
    certificate_hash = sha256(file(var.ssl_certificate_path))
  }

  provisioner "local-exec" {
    working_dir = "./monitoring"
    command     = <<-EOT
      kubectl create secret tls ingress-tls --key ${var.ssl_private_key_path} --cert ${var.ssl_certificate_path} -n monitoring
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
