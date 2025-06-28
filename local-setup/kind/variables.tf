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
  description = "The type of cluster executable to use. Allowed values: 'kind', 'podman kind', 'nvkind'."

  validation {
    condition = contains(["kind", "KIND_EXPERIMENTAL_PROVIDER=podman kind", "nvkind"], var.cluster_executable)
    error_message = "cluster_executable must be one of: 'kind', 'KIND_EXPERIMENTAL_PROVIDER=podman kind', or 'nvkind'."
  }

}
