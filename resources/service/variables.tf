variable "cluster_name" {
  description = "Name of the cluster where to deploy the service"
}

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

variable "image_uri" {
  description = "Image URI"
  default = "registry.hub.docker.com/kumjami/dummy-server:alpine"
}

variable "default_cpu" {
  description =  "Default task definition cpu."
  default = 256
}

variable "default_memory" {
  description =  "Default task definition memory."
  default = 512
}

variable "container_port" {
  description = "Container port"
  default = 3000
}

variable "instances" {
  description = "Number of servers instances"
  default = 1
}

variable "vpc_id" {
  description = "VPC id"
}

variable "service_subnets" {
  description = "Subnets identifiers where the service containers will live"
  type = "list"
}

variable "alb_security_group_id" {
  description = "Security group from where traffic will be allowed to access the service"
}

variable "logs_retention" {
  description = "Logs retention days"
  default = 7
}

variable "alb_target_group_arn" {
  description = "Target group of the ALB"
}

variable "enable_autoscaling" {
  description = "If true creates scalation policies"
  default = true
}

variable "cpu_to_scale_down" {
  description =  "Cpu percentage to scale down"
  default = 20
}

variable "min_capacity" {
  description =  "Minimum number of containers"
  default = 2
}


variable "max_capacity" {
  description =  "Maximum number of containers"
  default = 10
}

variable "cpu_to_scale_up" {
  description =  "Cpu percentage to scale up"
  default = 60
}

variable "egress_cidrs" {
  description = "Map of Cdirs blocks to allow as outbound TCP traffic. Keys are the description and values the Cdir block."
  type = "map"
  default = {}
}
