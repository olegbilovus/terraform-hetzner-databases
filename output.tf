output "ip" {
  value = hcloud_server.db-server.ipv4_address
}

output "ports" {
  value = "Available ports: ${var.enable_postgres ? "5433:PostgreSQL 8900:pgAdmin" : ""} ${var.enable_mongo ? "27018:MongoDB 8901:MongoExpress" : ""}"
}

locals {
  postgres_tunnels = var.enable_postgres ? "-L 127.0.0.1:5433:127.0.0.1:5432 -L 127.0.0.1:8900:127.0.0.1:8080" : ""
  mongo_tunnels    = var.enable_mongo ? "-L 127.0.0.1:27018:127.0.0.1:27017 -L 127.0.0.1:8901:127.0.0.1:8081" : ""
  ssh_tunnels      = trimspace("${local.postgres_tunnels} ${local.mongo_tunnels}")
}

output "ssh-tunnel-cmd" {
  value = "ssh -i hetzner -p ${var.ssh-port} ${local.ssh_tunnels != "" ? local.ssh_tunnels : ""} root@${hcloud_server.db-server.ipv4_address}"
}
