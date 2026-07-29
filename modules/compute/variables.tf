variable "environment" {
  type        = string
  description = "Deployment environment name (e.g. dev, prod), used for DB naming and tags"
}

variable "app_name" {
  type        = string
  description = "Application base name used for RDS naming and DB name composition"
}

variable "public_subnets" {
  type        = list(string)
  description = "The list of public subnets"
}

variable "nextcloud_sg_id" {
  type        = string
  description = "The ID of the Nextcloud security group"
}

variable "db_username" {
  type        = string
  description = "The username for the RDS database"
}

variable "docker_image" {
  type        = string
  description = "The Docker image to use for the Nextcloud instance"
}

variable "db_password" {
  type        = string
  description = "The password for the RDS database"
  sensitive   = true
}

variable "db_host" {
  type        = string
  description = "The host of the RDS instance"
}

variable "key_name" {
  type        = string
  description = "Key pair name for Nextcloud instance"
  default     = null
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for Nextcloud"
  default     = "t3.small"
}