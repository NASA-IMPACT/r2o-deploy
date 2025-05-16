variable "cluster_name" {
  description = "Name of the kind cluster"
  type        = string
  default     = "abdelhak"

}


variable "http_ingress_port" {
  type = number
}

variable "https_ingress_port" {
  type = number
}


variable "kind_experimental_provider" {
  type = string
}

variable "ssl_private_key_path" {
  default = "/home/opkind/ssl_certs/neo.nsstc.uah.edu.unencrypted.key"
}
variable "ssl_certificate_path" {
  default = "/home/opkind/ssl_certs/bundle-cert-intermediates-root.cer"
}
