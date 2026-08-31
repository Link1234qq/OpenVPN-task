variable "db_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the RDS DB subnet group (must be in the same VPC as RDS)"
}

variable "rds_sg_id" {
  type        = string
  description = "Security group ID attached to the RDS instance (typically allows MySQL from ASG)"
}

variable "environment" {
  type        = string
  description = "Deployment environment name (e.g. dev, prod), used for DB naming and tags"
}

variable "app_name" {
  type        = string
  description = "Application base name used for RDS naming and DB name composition"
}

variable "db_username" {
  type        = string
  description = "Master username for the RDS MySQL instance"
}

variable "db_password" {
  type        = string
  description = "Master password for the RDS MySQL instance"
  sensitive   = true
}
