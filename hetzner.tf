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

locals {
  ssh_public_key         = trimspace(resource.tls_private_key.ssh-key.public_key_openssh)
  enable_redis_seed_file = var.enable_redis && var.redis_dump_path != ""
  enable_redis_seed_s3   = var.enable_redis && var.redis_s3 != null
}

resource "hcloud_ssh_key" "db-server" {
  name       = "db-server-ssh-key"
  public_key = local.ssh_public_key
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
    public_key             = local.ssh_public_key
    password               = resource.random_password.ran_pwd.result
    ssh_port               = var.ssh-port
    enable_postgres        = var.enable_postgres
    enable_mongo           = var.enable_mongo
    enable_redis           = var.enable_redis
    enable_redis_seed_file = local.enable_redis_seed_file
    enable_redis_seed_s3   = local.enable_redis_seed_s3
    redis_s3 = var.redis_s3 != null ? var.redis_s3 : {
      endpoint   = ""
      bucket     = ""
      key        = ""
      access_key = ""
      secret_key = ""
      region     = "us-east-1"
    }
    enable_lazydocker      = var.enable_lazydocker
  })

  lifecycle {
    precondition {
      condition     = !(local.enable_redis_seed_file && local.enable_redis_seed_s3)
      error_message = "Set either redis_dump_path or redis_s3_* variables, not both."
    }
  }
}

resource "terraform_data" "redis_dump_import" {
  count = local.enable_redis_seed_file ? 1 : 0

  depends_on = [hcloud_server.db-server]

  # Re-run whenever the dump file content changes.
  triggers_replace = [filesha256(var.redis_dump_path)]

  connection {
    type        = "ssh"
    host        = hcloud_server.db-server.ipv4_address
    user        = "root"
    private_key = tls_private_key.ssh-key.private_key_openssh
    port        = var.ssh-port
    # Retries until SSH is available (server may still be mid-boot).
    timeout = "5m"
  }

  # Upload the dump so cloud-init's wait loop can pick it up.
  provisioner "file" {
    source      = var.redis_dump_path
    destination = "/tmp/dump.rdb"
  }

  # On initial provisioning cloud-init is still running and owns the import —
  # it will stop Redis, seed it, and reboot when it finds the file above.
  # On re-applies (server already up, cloud-init done) we import directly.
  provisioner "remote-exec" {
    inline = [
      "if cloud-init status 2>/dev/null | grep -q done; then docker stop redis && cp /tmp/dump.rdb /var/lib/docker/volumes/redisdata/_data/dump.rdb && chmod 644 /var/lib/docker/volumes/redisdata/_data/dump.rdb && rm -f /tmp/dump.rdb && docker start redis; fi"
    ]
  }
}
