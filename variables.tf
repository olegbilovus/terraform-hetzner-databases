variable "hcloud_token" {
  sensitive = true
  type      = string
}

variable "postgres-public_key" {
  type = string
}

variable "postgres_password" {
  sensitive = true
  type      = string
}

variable "ssh-port" {
  type    = number
  default = 22
}

variable "enable_postgres" {
  type    = bool
  default = true
}

variable "enable_mongo" {
  type    = bool
  default = true
}
