variable "hcloud_token" {
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

variable "enable_lazydocker" {
  type    = bool
  default = true
}
