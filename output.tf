output "ip" {
  value = hcloud_server.postgres.ipv4_address
}

output "warn" {
  value = "Run the ssh port forward in an external terminal, VSCode may not be allowed to open ports. It may take a couple of minutes before the server is accessible."
}

locals {
  postgres_tunnels = var.enable_postgres ? "-L 127.0.0.1:5433:127.0.0.1:5432 -L 127.0.0.1:8900:127.0.0.1:8080" : ""
  mongo_tunnels    = var.enable_mongo ? "-L 127.0.0.1:27018:127.0.0.1:27017 -L 127.0.0.1:8901:127.0.0.1:8081" : ""
  ssh_tunnels      = trimspace("${local.postgres_tunnels} ${local.mongo_tunnels}")
}

output "ssh-tunnel-cmd" {
  value = "ssh -i hetzner -p ${var.ssh-port} ${local.ssh_tunnels != "" ? local.ssh_tunnels : ""} root@${hcloud_server.postgres.ipv4_address}"
}
