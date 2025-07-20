
resource "helm_release" "kube-prometheus" {
  name       = "prometheus-stack"
  depends_on = [local_file.kube-prometheus-values]
  namespace  = "monitoring"
  create_namespace = true
  version    = "75.12.0"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  values = [local_file.kube-prometheus-values.content]
}


resource "local_file" "kube-prometheus-values" {
  filename               = "${path.module}/values.yaml"
  content                = templatefile("${path.module}/values.yaml.tmpl", {
    grafana_admin        = var.grafana_admin
    grafana_password     = var.grafana_password
    domain_name          = var.domain_name
    config_tmpl_hash     = sha256(file("${path.module}/values.yaml.tmpl"))
  })
  
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
