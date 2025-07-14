variable "cluster_name" {
  description = "Name of the kind cluster"
  type        = string

}


variable "http_ingress_port" {
  type = number
}

variable "https_ingress_port" {
  type = number
}


variable "ssl_private_key_path" {
}
variable "ssl_certificate_path" {
}

variable "cluster_executable" {
  type = string
  description = "The type of cluster executable to use. Allowed values: 'kind create cluster --config', 'KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster', 'nvkind cluster create --config-template'."

  validation {
    condition = contains(["kind create cluster --config", "KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster", "nvkind cluster create --config-template"], var.cluster_executable)
    error_message = "The type of cluster executable to use. Allowed values: 'kind create cluster --config', 'KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster', 'nvkind cluster create --config-template'."
  }

}


variable "oidc_issuer_url" {
  default = "https://d2oix8zjvfh7fy.cloudfront.net"
}

variable "oidc_s3_bucketname" {
  default = "r2o-neo-kind-oidc"
}

variable "oidc_role_arn" {
  default = "arn:aws:iam::244822573120:role/NeoKindPodRole"
}
