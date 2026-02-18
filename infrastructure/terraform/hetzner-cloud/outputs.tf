output "server_ids" {
  description = "IDs of the created servers"
  value       = hcloud_server.node[*].id
}

output "server_names" {
  description = "Names of the created servers"
  value       = hcloud_server.node[*].name
}

output "server_ips" {
  description = "Public IPv4 addresses of the created servers"
  value       = hcloud_server.node[*].ipv4_address
}

output "server_ipv6" {
  description = "IPv6 addresses of the created servers"
  value       = hcloud_server.node[*].ipv6_address
}

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = hcloud_load_balancer.main.id
}

output "load_balancer_ip" {
  description = "Public IPv4 address of the load balancer"
  value       = hcloud_load_balancer.main.ipv4
}
