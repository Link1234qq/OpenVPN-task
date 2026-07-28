variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet IDs"
}

variable "openvpn_sg_id" {
  type        = string
  description = "Security group for OpenVPN (UDP 1194)"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR pushed to VPN clients for split-tunnel access"
}

variable "vpn_client_cidr" {
  type        = string
  description = "OpenVPN client address pool"
  default     = "10.8.0.0/24"
}

variable "key_name" {
  type        = string
  description = "SSH key pair name for OpenVPN instance"
  default     = null
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
