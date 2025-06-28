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

variable "cluster_executable" {
  type = string
  description = "The type of cluster executable to use. Allowed values: 'kind', 'podman kind', 'nvkind'."

  validation {
    condition = contains(["kind", "KIND_EXPERIMENTAL_PROVIDER=podman kind", "nvkind"], var.cluster_executable)
    error_message = "cluster_executable must be one of: 'kind', 'KIND_EXPERIMENTAL_PROVIDER=podman kind', or 'nvkind'."
  }
  default = "nvkind"

}

variable "manual_setup" {
  type    = bool
  default = false
}

variable "ssl_private_key_path" {
  default = "/home/opkind/ssl_certs/neo.nsstc.uah.edu.unencrypted.key"
}
variable "ssl_certificate_path" {
  default = "/home/opkind/ssl_certs/bundle-cert-intermediates-root.cer"
}

variable "domain_name" {
  type = string
  default = "kind.neo.nsstc.uah.edu"
  
}
