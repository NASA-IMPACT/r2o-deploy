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
  sensitive = true
}
variable "ssl_certificate_path" {
  sensitive = true
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
  type = string
  description = "The URL of the OIDC issuer."
}

variable "oidc_s3_bucketname" {
  type = string
  description = "The name of the S3 bucket where the OIDC credentials will be stored"
}

variable "oidc_role_arn" {
  type = string
  description = "The ARN of the IAM role that has permissions to access the S3 bucket."
}

variable "cloudfront_id" {
  type = string
  description = "The CloudFront ID for the distribution."
}
