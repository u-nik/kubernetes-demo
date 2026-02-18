variable "cluster_name" {
  description = "Name of the KIND cluster"
  type        = string
  default     = "kubernetes-demo"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.cluster_name)) && length(var.cluster_name) >= 2
    error_message = "Cluster name must consist of lowercase alphanumeric characters or '-', and must start and end with an alphanumeric character."
  }
}
