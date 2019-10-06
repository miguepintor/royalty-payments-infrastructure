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

variable "alb_subnets" {
  description = "Subnet identifiers to put the alb in between"
  type = "list"
}

variable "internal" {
  description = "Indicates whether the alb is public or private"
  default = true
}

variable "vpc_id" {
  description = "VPC identifier"
}

variable "target_group_port" {
  description = "Target group port in which the registered instances will be balanced"
  default = 3000
}

variable "ingress_cidrs" {
  description = "Map of Cdirs blocks to allow as inbound traffic. Keys are the description and values the Cdir block."
  type = "map"
}

variable "egress_cidrs" {
  description = "Map of Cdirs blocks to allow as outbound traffic. Keys are the description and values the Cdir block."
  type = "map"
}

variable "health_check_path" {
  description = "Path to verify that the service is responding"
  default = "/status"
}