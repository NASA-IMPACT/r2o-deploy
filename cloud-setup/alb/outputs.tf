output "proxy_url" {
  value = "https://${lower(var.subdomain)}.${var.proxy_domain_name}"
}