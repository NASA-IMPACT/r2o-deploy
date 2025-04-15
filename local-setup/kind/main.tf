
resource "local_file" "kind-template" {

  content = templatefile("${path.root}/kind/config.yaml.tmpl",
    {
      http_ingress_port  = var.http_ingress_port
      https_ingress_port = var.https_ingress_port
      config_tmpl_hash = sha256(file("${path.root}/kind/config.yaml.tmpl"))
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

    working_dir = "./kind"
    command     = "systemd-run --scope --user -p \"Delegate=yes\" kind create cluster --name ${var.cluster_name} --config=config.yaml"
  }
}



resource "null_resource" "setup-kind-ingress" {
  depends_on = [null_resource.setup-kind]
  triggers = {
    ingress_config_hash = sha256(file("${path.root}/kind/ingress-nginx.yaml"))
  }
  provisioner "local-exec" {
    working_dir = "./kind"
    command     = "kubectl apply -f ingress-nginx.yaml"
  }
}
