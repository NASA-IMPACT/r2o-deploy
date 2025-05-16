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

