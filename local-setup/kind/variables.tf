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


variable "kind_experimental_provider" {
  type = string
}

variable "ssl_private_key_path" {
}
variable "ssl_certificate_path" {
}


