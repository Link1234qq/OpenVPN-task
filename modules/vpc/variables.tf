variable "azs" {
  type        = list(string)
  description = "Availability Zones"

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

variable "private_subnets" {
  type        = list(string)
  description = "The list of private subnets"
}

variable "public_subnets" {
  type        = list(string)
  description = "The list of public subnets"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "environment" {
  type        = string
  description = "The environment"
}

variable "app_name" {
  type        = string
  description = "Application base name used in mandatory resource tags"
}
