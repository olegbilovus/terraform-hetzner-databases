output "ip" {
  value = hcloud_server.postgres.ipv4_address
}

output "ssh-tunnel-cmd" {
  value = "ssh -i hetzner -L 127.0.0.1:5433:127.0.0.1:5432 -L 127.0.0.1:8900:127.0.0.1:8080 root@${hcloud_server.postgres.ipv4_address}"
}