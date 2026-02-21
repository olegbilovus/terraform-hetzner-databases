# Hetzner PostgreSQL Deployment

This Terraform project deploys a PostgreSQL database server with pgAdmin on Hetzner Cloud. The setup includes Docker containers running PostgreSQL 18 and pgAdmin4, configured for secure remote access via SSH tunneling.

## Architecture

The infrastructure includes:

- Hetzner Cloud server (cx23) running Ubuntu 24.04 in Falkenstein datacenter
- Docker network with PostgreSQL 18 and pgAdmin4 containers
- Firewall configured to allow SSH access only (port 22)
- PostgreSQL and pgAdmin bound to loopback for security
- Persistent volumes for database and pgAdmin data

## Prerequisites

Before deploying, ensure you have:

1. **Terraform** (or OpenTofu) installed on your local machine
2. **Hetzner Cloud account** with API token
3. **SSH key pair** for server access
4. **Hetzner Cloud API token** with read/write permissions

## Terraform Variables

| Variable              | Type   | Description                         | Sensitive |
| --------------------- | ------ | ----------------------------------- | --------- |
| `hcloud_token`        | string | Hetzner Cloud API token             | Yes       |
| `postgres-public_key` | string | SSH public key for server access    | No        |
| `postgres_password`   | string | Password for PostgreSQL and pgAdmin | Yes       |

## Accessing the Services

### SSH Tunnel

Both PostgreSQL and pgAdmin are only accessible via SSH tunnel for security. Use the command provided in the output:

```bash
ssh -i hetzner -L 127.0.0.1:5433:127.0.0.1:5432 -L 127.0.0.1:8900:127.0.0.1:8080 root@<server-ip>
```

This command creates two tunnels:

- **PostgreSQL**: Local port 5433 → Remote port 5432
- **pgAdmin**: Local port 8900 → Remote port 8080

### Connecting to PostgreSQL

With the SSH tunnel active, connect to PostgreSQL using:

```bash
psql -h 127.0.0.1 -p 5433 -U postgres
```

Or use any PostgreSQL client with these connection details:

- Host: `127.0.0.1`
- Port: `5433`
- Username: `postgres`
- Password: The password you set in `terraform.tfvars`

### Accessing pgAdmin

With the SSH tunnel active, open your browser and navigate to:

```
http://127.0.0.1:8900
```

Login credentials:

- Email: `postgres@example.com`
- Password: The password you set in `terraform.tfvars`

## Infrastructure Details

### Server Specifications

- **Type**: cx23 (2 vCPU, 4 GB RAM, 40 GB SSD)
- **Location**: Falkenstein, Germany (fsn1)
- **Operating System**: Ubuntu 24.04 LTS
- **IPv4/IPv6**: Both enabled
- **Costs**: €0.006/hour + €0.00098/h for IPv4 (as of February 2026)

### Docker Containers

**PostgreSQL 18**

- Image: `postgres:18`
- Port: 5432 (localhost only)
- Data volume: `pgdata`
- Auto-restart: Always

**pgAdmin4**

- Image: `dpage/pgadmin4:latest`
- Port: 8080 (localhost only)
- Data volume: `pgadmin`
- Auto-restart: Always

## Outputs

After deployment, the following outputs are available:

| Output           | Description                                 |
| ---------------- | ------------------------------------------- |
| `ip`             | Public IPv4 address of the server           |
| `ssh-tunnel-cmd` | Complete SSH tunnel command for easy access |

View outputs anytime with:

```bash
terraform output
```
