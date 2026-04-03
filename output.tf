output "ip" {
  value = hcloud_server.db-server.ipv4_address
}

locals {
  available_ports = merge(
    var.enable_postgres ? {
      postgres = {
        local_port  = 5433
        remote_port = 5432
        service     = "PostgreSQL"
      }
      pgadmin = {
        local_port  = 8900
        remote_port = 8080
        service     = "pgAdmin"
      }
    } : {},
    var.enable_mongo ? {
      mongo = {
        local_port  = 27018
        remote_port = 27017
        service     = "MongoDB"
      }
      mongo_express = {
        local_port  = 8901
        remote_port = 8081
        service     = "Mongo Express"
      }
    } : {}
  )

  postgres_tunnels = var.enable_postgres ? "-L 127.0.0.1:5433:127.0.0.1:5432 -L 127.0.0.1:8900:127.0.0.1:8080" : ""
  mongo_tunnels    = var.enable_mongo ? "-L 127.0.0.1:27018:127.0.0.1:27017 -L 127.0.0.1:8901:127.0.0.1:8081" : ""
  ssh_tunnels      = trimspace("${local.postgres_tunnels} ${local.mongo_tunnels}")
}

output "available_ports" {
  value = local.available_ports
}

output "ssh-tunnel-cmd" {
  value = "ssh -i hetzner -p ${var.ssh-port} ${local.ssh_tunnels != "" ? local.ssh_tunnels : ""} root@${hcloud_server.db-server.ipv4_address}"
}

output "password" {
  value = nonsensitive(random_password.ran_pwd.result)
}
