variable "app_name" {
  type        = string
  description = "Application name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod, etc.)"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs for Prometheus instance"
}

variable "prometheus_sg_id" {
  type        = string
  description = "Security group ID for Prometheus"
}

variable "key_name" {
  type        = string
  description = "Key pair name for Prometheus instance"
  default     = null
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for Prometheus"
  default     = "t3.micro"
}

variable "docker_image" {
  type        = string
  description = "Prometheus Docker image"
  default     = "prom/prometheus:latest"
}
