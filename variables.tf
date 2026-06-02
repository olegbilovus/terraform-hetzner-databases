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
  description = "Optional local path to a dump.rdb file to seed the Redis instance. Mutually exclusive with redis_s3_* variables."
}

variable "redis_s3" {
  type = object({
    endpoint   = string
    bucket     = string
    key        = string
    access_key = string
    secret_key = string
    region     = optional(string, "us-east-1")
  })
  default     = null
  sensitive   = true
  description = "S3-compatible source for seeding Redis. Mutually exclusive with redis_dump_path."
}

variable "enable_lazydocker" {
  type    = bool
  default = true
}
