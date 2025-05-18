# === Manually steup kind cluster

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


resource "null_resource" "setup-kind" {
  depends_on = [local_file.kind-template]

  triggers = {
    config_hash = sha256(file("${path.root}/kind/config.yaml.tmpl"))
  }

  provisioner "local-exec" {
    when        = create
    working_dir = "./kind"
    command     = var.kind_experimental_provider == "podman" ? (
    "KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster --name ${var.cluster_name} --config=config.yaml"
    ) : (
    "kind create cluster --name ${var.cluster_name} --config=config.yaml"
    )

  }
}
