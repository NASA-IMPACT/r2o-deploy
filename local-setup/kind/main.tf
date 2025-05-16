resource "local_file" "kind-template" {

  content = templatefile("${path.root}/kind/config.yaml.tmpl",
    {
      http_ingress_port  = var.http_ingress_port
      https_ingress_port = var.https_ingress_port
      config_tmpl_hash   = sha256(file("${path.root}/kind/config.yaml.tmpl"))
    }


  )
  filename = "${path.root}/kind/config.yaml"
}

data "external" "kind_cluster_check" {
  program = ["bash", "${path.root}/../scripts/check_cluster_exists.sh", var.cluster_name]
}
resource "null_resource" "setup-kind" {
  depends_on = [local_file.kind-template]

  triggers = {
    config_hash    = sha256(file("${path.root}/kind/config.yaml.tmpl"))
    cluster_exists = data.external.kind_cluster_check.result["exists"]
  }

  provisioner "local-exec" {
    when        = create
    working_dir = "./kind"
    command     = data.external.kind_cluster_check.result["exists"] == "true" ? "echo 'Kind cluster already exists, skipping creation'" : (
    var.kind_experimental_provider == "podman" ? (
    "KIND_EXPERIMENTAL_PROVIDER=podman && kind create cluster --name ${var.cluster_name} --config=config.yaml"
    ) : (
    "kind create cluster --name ${var.cluster_name} --config=config.yaml"
    )
    )
  }
}


resource "null_resource" "setup-kind-ingress" {
  depends_on = [null_resource.setup-kind]
  triggers   = {
    ingress_config_hash = sha256(file("${path.root}/kind/ingress-nginx.yaml"))
  }
  provisioner "local-exec" {
    working_dir = "./kind"
    command     = "kubectl apply -f ingress-nginx.yaml"
  }
}


resource "null_resource" "setup-certificate-secrets" {
  for_each = toset(var.ingress_namespaces)

  depends_on = [null_resource.setup-kind-ingress]

  triggers = {
    private_key_hash = sha256(file(var.ssl_private_key_path))
    certificate_hash = sha256(file(var.ssl_certificate_path))
    namespace        = each.key
  }

  provisioner "local-exec" {
    working_dir = "./kind"
    command     = "kubectl create secret tls ingress-tls --key ${var.ssl_private_key_path} --cert ${var.ssl_certificate_path} -n ${each.key}"
  }
}
