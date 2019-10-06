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

variable "vpc_id" {
  description = "VPC identifier"
}

variable "ingress_cidrs" {
  description = "Map of Cdirs blocks to allow as inbound traffic. Keys are the description and values the Cdir block."
  type = "map"
}