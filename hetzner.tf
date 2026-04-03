resource "tls_private_key" "ssh-key" {
  algorithm = "ED25519"
}

# On windows, the file permission is ignored, you can set it manually with `icacls hetzner /inheritance:r /grant:r "$($env:USERNAME):R"`
resource "local_file" "ssh_key" {
  content         = resource.tls_private_key.ssh-key.private_key_openssh
  filename        = "${path.module}/hetzner"
  file_permission = "0600"
}

resource "local_file" "ssh_key_pub" {
  content         = resource.tls_private_key.ssh-key.public_key_openssh
  filename        = "${path.module}/hetzner.pub"
  file_permission = "0644"
}

resource "random_password" "ran_pwd" {
  length      = 16
  special     = false
  min_numeric = 5
  upper       = true
  lower       = true
  numeric     = true
}

resource "hcloud_ssh_key" "db-server" {
  name       = "db-server-ssh-key"
  public_key = resource.tls_private_key.ssh-key.public_key_openssh
}

resource "hcloud_firewall" "ssh-only" {
  name = "ssh-only"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = var.ssh-port
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_server" "db-server" {
  name        = "db-server"
  image       = "ubuntu-24.04"
  server_type = "cx23"
  location    = "fsn1"

  ssh_keys     = [hcloud_ssh_key.db-server.id]
  firewall_ids = [hcloud_firewall.ssh-only.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    public_key        = resource.tls_private_key.ssh-key.public_key_openssh
    password          = resource.random_password.ran_pwd.result
    ssh_port          = var.ssh-port
    enable_postgres   = var.enable_postgres
    enable_mongo      = var.enable_mongo
    enable_lazydocker = var.enable_lazydocker
  })
}
