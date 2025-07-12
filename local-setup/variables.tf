variable "cluster_name" {
  description = "Name of the kind cluster"
  type        = string

}

variable "http_ingress_port" {
  type    = number
  default = 8888
}

variable "https_ingress_port" {
  type    = number
  default = 4444
}


variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
}

variable "github_app_private_key_path" {
  description = "Path to the GitHub App Private Key"
  type        = string
}

variable "prefix" {
  type = string
}


variable "manual_setup" {
  type    = bool
  default = false
}

variable "ssl_private_key_path" {
  default = "/home/ubuntu/r2o-deploy/local-setup/key.pem"
}
variable "ssl_certificate_path" {
  default = "/home/ubuntu/r2o-deploy/local-setup/cert.pem"
}

variable "domain_name" {
  type = string
  default = "kind.neo.nsstc.uah.edu"
  
}

variable "cluster_executable" {
  type = string
  description = "The type of cluster executable to use. Allowed values: 'kind create cluster --config', 'KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster', 'nvkind cluster create --config-template'."

  validation {
    condition = contains(["kind create cluster --config", "KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster", "nvkind cluster create --config-template"], var.cluster_executable)
    error_message = "The type of cluster executable to use. Allowed values: 'kind create cluster --config', 'KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster', 'nvkind cluster create --config-template'."
  }

  default = "nvkind cluster create --config-template"

}

variable "grafana_admin" {
  default = "admin"
}

variable "grafana_password" {
  default = "r2oadmins"
}


variable "dot_aws_dir_path" {
  type        = string
  description = "The path to the .aws directory."
  default = "/home/opkind/.aws"
  
}
