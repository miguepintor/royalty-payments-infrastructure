variable "tags" {
  description = "Common tags assigned to all resources"
  type        = "map"
}

variable "app_name" {
  description = "Application name"
}

variable "environment" {
  description = "Environment name: int, qa, stg or production"
}

variable "redis_port" {
  description = "Port in which redis will be listening"
  default = 6379
}

variable "redis_subnets" {
  description = "Subnet identifiers where to host redis"
  type = "list"
}