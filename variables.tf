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

variable "enable_redis" {
  type    = bool
  default = true
}

variable "redis_dump_path" {
  type        = string
  default     = ""
  description = "Optional local path to a dump.rdb file to seed the Redis instance. When set, the file is uploaded and imported on every apply where the content changes."
}

variable "enable_lazydocker" {
  type    = bool
  default = true
}
