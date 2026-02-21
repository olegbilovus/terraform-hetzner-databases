resource "hcloud_ssh_key" "postgres" {
  name       = "postgres-ssk-key"
  public_key = var.postgres-public_key
}

resource "hcloud_firewall" "ssh-only" {
  name = "ssh-only"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = 22
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_server" "postgres" {
  name        = "postgres"
  image       = "ubuntu-24.04"
  server_type = "cx23"
  location    = "fsn1"

  ssh_keys     = [hcloud_ssh_key.postgres.id]
  firewall_ids = [hcloud_firewall.ssh-only.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    public_key = var.postgres-public_key
    password   = var.postgres_password
  })
}
