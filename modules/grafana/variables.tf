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
  description = "List of public subnet IDs for Grafana instance"
}

variable "grafana_sg_id" {
  type        = string
  description = "Security group ID for Grafana"
}

variable "prometheus_private_ip" {
  type        = string
  description = "Private IP of Prometheus instance"
}
variable "key_name" {
  type        = string
  description = "Key pair name for Grafana instance"
  default     = null
}
variable "instance_type" {
  type        = string
  description = "EC2 instance type for Grafana"
  default     = "t3.micro"
}

variable "docker_image" {
  type        = string
  description = "Grafana Docker image"
  default     = "grafana/grafana:latest"
}

variable "grafana_admin_password" {
  type        = string
  description = "Grafana admin password"
  default     = "admin123"
  sensitive   = true
}
