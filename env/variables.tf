variable "azs" {
  type = list(string)

  validation {
    condition = alltrue([
      for az in var.azs : contains([
        "us-east-1a",
        "us-east-1b",
        "us-east-1c",
        "us-east-1d",
        "us-east-1e",
        "us-east-1f"
      ], az)
    ])
    error_message = "Supported AZs are us-east-1a through us-east-1f."
  }
}

variable "app_name" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "vpc_cidr_block" {
  type = string
}

variable "environment" {
  type = string
}

variable "managed_by" {
  type        = string
  description = "Owner or team responsible for resources (mandatory tag)"
}

variable "db_username" {
  type        = string
  description = "RDS master username (stored in Secrets Manager with the generated password)"
}

variable "docker_image" {
  type = string
}

variable "allowed_cidr" {
  type        = string
  description = "Your current public IP as CIDR (curl ifconfig.me)/32 — required for browser access"
  default     = "85.223.209.18/32"
}

variable "vpn_client_cidr" {
  type        = string
  description = "OpenVPN client network"
  default     = "10.8.0.0/24"
}

variable "key_name" {
  type        = string
  description = "SSH key pair name for OpenVPN instance"
  default     = null
}
