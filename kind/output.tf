output "setup-kubectl-context" {
  value = "kubectl cluster-info --context kind-${var.cluster_name}"

}
