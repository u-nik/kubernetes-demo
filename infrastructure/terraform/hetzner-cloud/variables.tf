variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "op_service_account_token" {
  description = "1Password Service Account token (alternatively set OP_SERVICE_ACCOUNT_TOKEN env var)"
  type        = string
  sensitive   = true
}

variable "op_vault_uuid" {
  description = "1Password Vault UUID where the SSH key item will be stored"
  type        = string
}

variable "op_item_uuid" {
  description = "UUID of the 1Password item that contains the public key"
  type        = string
  nullable    = true
  default     = null
  validation {
    condition     = var.op_item_uuid != null
    error_message = "Set an op_item_uuid."
  }
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
