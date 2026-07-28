variable "vpc_id" {
  type        = string
  description = "VPC ID where security groups are created"
}

variable "environment" {
  type        = string
  description = "Deployment environment name (e.g. dev, prod), used for tagging"
}

variable "app_name" {
  type        = string
  description = "Application base name used in mandatory resource tags"
}

variable "allowed_cidr" {
  type        = string
  description = "Your public IP in CIDR form (e.g. 1.2.3.4/32) for HTTP access to Nextcloud"
  default     = "85.223.209.18/32"
}

variable "vpn_client_cidr" {
  type        = string
  description = "CIDR of OpenVPN clients (Grafana / Prometheus UI)"
  default     = "10.8.0.0/24"
}

variable "prometheus_allowed_cidr" {
  type        = string
  description = "CIDR range allowed to access Prometheus"
  default     = "10.0.0.0/16"
}