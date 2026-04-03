# Hetzner Database Deployment

This Terraform project deploys a database server on Hetzner Cloud with optional PostgreSQL + pgAdmin, MongoDB + Mongo Express, and Lazydocker stacks. Services run in Docker containers and are exposed only through SSH tunneling for secure remote access. The SSH key for server access is generated automatically during deployment.

## Architecture

The infrastructure includes:

- Hetzner Cloud server (cx23) running Ubuntu 24.04 in Falkenstein datacenter
- Firewall configured to allow SSH access only (customizable with `ssh-port`)
- SSH password authentication disabled (`ssh_pwauth: false`)
- Optional PostgreSQL 18 + pgAdmin4 stack
- Optional MongoDB 8 + Mongo Express stack
- Optional Lazydocker TUI for Docker management
- All database/web UI ports bound to loopback for security
- Persistent Docker volumes for stateful services
- SSH key pair is generated automatically and saved as `hetzner` (private) and `hetzner.pub` (public) in the project directory. On Windows, the private key file permissions may need to be set manually with `icacls hetzner /inheritance:r /grant:r "$($env:USERNAME):R"`.

## Prerequisites

Before deploying, ensure you have:

1. **Terraform** (or OpenTofu) installed on your local machine
2. **Hetzner Cloud account** with API token
3. **Hetzner Cloud API token** with read/write permissions

> **Note:** You do **not** need to provide your own SSH key. The deployment will generate a new SSH key pair (`hetzner` and `hetzner.pub`) in the project directory for server access.

## Terraform Variables

| Variable              | Type   | Description                         | Sensitive |
| --------------------- | ------ | ----------------------------------- | --------- |
| `hcloud_token`        | string | Hetzner Cloud API token              | Yes      |
| `ssh-port`            | number | SSH port opened in firewall and SSHD | No       |
| `enable_postgres`     | bool   | Deploy PostgreSQL + pgAdmin          | No       |
| `enable_mongo`        | bool   | Deploy MongoDB + Mongo Express       | No       |
| `enable_lazydocker`   | bool   | Deploy Lazydocker TUI for Docker      | No       |

### Example `terraform.tfvars`

```hcl
hcloud_token      = "replace-with-hcloud-token"

ssh-port          = 443
enable_postgres   = true
enable_mongo      = true
enable_lazydocker = true
```

## Generated Service Password

Terraform now generates a strong shared password automatically for PostgreSQL, pgAdmin, MongoDB, and Mongo Express.

Retrieve it with:

```bash
terraform output -raw password
```

## Accessing the Services

### View Available Ports

Use the structured output for a clean port mapping:

```bash
terraform output available_ports
```

## SSH Key Usage

After deployment, a new SSH key pair will be created in your project directory:

- `hetzner` (private key)
- `hetzner.pub` (public key)

Use the `hetzner` private key for SSH access and tunneling. Example:

```bash
ssh -i hetzner -p <ssh-port> root@<server-ip>
```

### SSH Tunnel

Enabled services are only accessible via SSH tunnel. Use the command from Terraform output:

```bash
terraform output -raw ssh-tunnel-cmd
```

This output includes the correct `-p <ssh-port>` and only the tunnels for enabled stacks.

When both stacks are enabled, the command includes:

- **PostgreSQL**: Local port 5433 → Remote port 5432
- **pgAdmin**: Local port 8900 → Remote port 8080
- **MongoDB**: Local port 27018 → Remote port 27017
- **Mongo Express**: Local port 8901 → Remote port 8081

Run the printed SSH command in an external terminal and keep it open while using the services.

### Connecting to PostgreSQL

With the SSH tunnel active, connect to PostgreSQL using:

```bash
psql -h 127.0.0.1 -p 5433 -U postgres
```

Or use any PostgreSQL client with these connection details:

- Host: `127.0.0.1`
- Port: `5433`
- Username: `postgres`
- Password: The value from `terraform output -raw password`

### Accessing pgAdmin

With the SSH tunnel active, open your browser and navigate to:

```
http://127.0.0.1:8900
```

Login credentials:

- Email: `postgres@example.com`
- Password: The value from `terraform output -raw password`

### Connecting to MongoDB

With the SSH tunnel active, connect using:

```bash
mongosh "mongodb://admin:<password>@127.0.0.1:27018"
```

Or use your MongoDB client with:

- Host: `127.0.0.1`
- Port: `27018`
- Username: `admin`
- Password: The value from `terraform output -raw password`
- Auth database: `admin`

### Accessing Mongo Express

With the SSH tunnel active, open:

```
http://127.0.0.1:8901
```

Login credentials:

- Username: `admin`
- Password: The value from `terraform output -raw password`

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

**MongoDB 8**

- Image: `mongo:8`
- Port: 27017 (localhost only)
- Data volume: `mongodata`
- Auto-restart: Always

**Mongo Express**

- Image: `mongo-express:latest`
- Port: 8081 (localhost only)
- Auto-restart: Always

## Outputs

After deployment, the following outputs are available:

| Output           | Description                                 |
| ---------------- | ------------------------------------------- |
| `ip`             | Public IPv4 address of the server           |
| `available_ports`| Structured local/remote port mapping for enabled stacks |
| `ssh-tunnel-cmd` | Complete SSH tunnel command for easy access |
| `password`       | Generated shared password for enabled services |

View outputs anytime with:

```bash
terraform output
```
