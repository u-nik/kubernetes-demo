terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    onepassword = {
      source  = "1password/onepassword"
      version = "~> 2.1"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "onepassword" {
  service_account_token = var.op_service_account_token
}

data "onepassword_item" "ssh_key" {
  vault = var.op_vault_uuid
  uuid  = var.op_item_uuid
}

locals {
  ssh_public_key = data.onepassword_item.ssh_key.password
}

resource "hcloud_ssh_key" "default" {
  name       = "${var.environment}-ssh-key"
  public_key = local.ssh_public_key

  lifecycle {
    precondition {
      condition     = local.ssh_public_key != null && length(local.ssh_public_key) > 0
      error_message = "No public SSH key found. Ensure the 1Password login item has the public key stored in the password field."
    }
  }
}

resource "hcloud_server" "node" {
  count       = 3
  name        = "node-${count.index + 1}"
  server_type = "cx33"
  image       = "ubuntu-24.04"
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]

  labels = {
    environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "hcloud_load_balancer" "main" {
  name               = "${var.environment}-lb"
  load_balancer_type = "lb11"
  location           = var.location

  labels = {
    environment = var.environment
  }
}

resource "hcloud_load_balancer_target" "nodes" {
  for_each = { for idx, server in hcloud_server.node : idx => server }

  type             = "server"
  load_balancer_id = hcloud_load_balancer.main.id
  server_id        = each.value.id
}
