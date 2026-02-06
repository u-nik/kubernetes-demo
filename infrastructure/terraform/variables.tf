variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "The location where servers will be created"
  type        = string
  default     = "nbg1"
}

variable "environment" {
  description = "Environment label for the servers"
  type        = string
  default     = "kubernetes-demo"
}
