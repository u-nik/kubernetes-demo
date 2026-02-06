terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_server" "node" {
  count       = 3
  name        = "node-${count.index + 1}"
  server_type = "cx33"
  image       = "ubuntu-24.04"
  location    = var.location

  labels = {
    environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}
