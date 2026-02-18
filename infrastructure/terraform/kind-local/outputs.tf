output "cluster_name" {
  description = "Name of the KIND cluster"
  value       = kind_cluster.default.name
}

output "kubeconfig" {
  description = "Kubeconfig for the KIND cluster"
  value       = kind_cluster.default.kubeconfig
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Path to the exported kubeconfig file"
  value       = kind_cluster.default.kubeconfig_path
}

output "endpoint" {
  description = "Kubernetes API endpoint"
  value       = kind_cluster.default.endpoint
}

output "client_certificate" {
  description = "Client certificate for authenticating to the cluster"
  value       = kind_cluster.default.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key for authenticating to the cluster"
  value       = kind_cluster.default.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate for the cluster"
  value       = kind_cluster.default.cluster_ca_certificate
  sensitive   = true
}
