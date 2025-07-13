resource "local_file" "kind-template" {

  content = templatefile("${path.root}/kind/config.yaml.tmpl",
    {
      http_ingress_port  = var.http_ingress_port
      https_ingress_port = var.https_ingress_port
      cluster_name  = var.cluster_name
      config_tmpl_hash   = sha256(file("${path.root}/kind/config.yaml.tmpl"))
      oidc_issuer_url = var.oidc_issuer_url
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
    command     = "kind delete cluster --name ${var.cluster_name}; ${var.cluster_executable}=config.yaml"
  }
    
  
}

resource "null_resource" "setup-jwt" {
  depends_on = [null_resource.setup-kind]


  provisioner "local-exec" {
    working_dir = "./kind"
    environment = {
      ISSUER_URL = var.oidc_issuer_url
      CLUSTER_NAME = var.cluster_name
      S3_BUCKET = var.oidc_s3_bucketname
      GENERATE_JWT_HASH   = sha256(file("${path.root}/kind/generate_jwt.sh"))
    }
    command     = "echo running RENERATE_JWT hash $GENERATE_JWT_HASH; bash generate_jwt.sh"
  }
    
  
}
resource "null_resource" "setup-service-account" {
  depends_on = [null_resource.setup-kind, null_resource.setup-jwt]
  triggers   = {
    ingress_config_hash = sha256(file("${path.root}/kind/serviceaccount.yaml"))
  }
  provisioner "local-exec" {
    working_dir = "./kind"
    command     = "kubectl apply -f serviceaccount.yaml"
  }
}

resource "kubernetes_config_map_v1" "oidc_config" {
  depends_on = [null_resource.setup-kind, null_resource.setup-jwt]
  metadata {
    name      = "oidc-envs"
    namespace = "default"
  }

  # Define your key-value pairs directly here
  data = {
  AWS_ROLE_ARN="arn:aws:iam::244822573120:role/NeoKindPodRole"
  AWS_WEB_IDENTITY_TOKEN_FILE="/var/run/secrets/kubernetes.io/serviceaccount/token"
  AWS_REGION="us-west-2"
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

  depends_on = [null_resource.setup-kind-ingress]

  triggers = {
    private_key_hash = sha256(file(var.ssl_private_key_path))
    certificate_hash = sha256(file(var.ssl_certificate_path))
  }

  provisioner "local-exec" {
    working_dir = "./kind"
    command     = <<-EOT
      kubectl create secret tls ingress-tls --key ${var.ssl_private_key_path} --cert ${var.ssl_certificate_path}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "helm_release" "gpu_operator" {
  name       = "${var.cluster_name}-gpu-operator"
  depends_on = [null_resource.setup-certificate-secrets]
  namespace  = "gpu-operator"
  create_namespace = true

  repository = "https://nvidia.github.io/gpu-operator"
  chart      = "gpu-operator"

  values = [
    yamlencode({
      driver = {
        enabled = false
      }
    })
  ]

  wait = true
}
