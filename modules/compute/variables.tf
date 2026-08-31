variable "environment" {
  type        = string
  description = "Deployment environment name (e.g. dev, prod), used for DB naming and tags"
}

variable "app_name" {
  type        = string
  description = "Application base name used for RDS naming and DB name composition"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the ALB target group"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet IDs for ECS tasks and EFS mount targets"
}

variable "nextcloud_alb_sg_id" {
  type        = string
  description = "Security group ID for the Nextcloud ALB"
}

variable "nextcloud_ecs_sg_id" {
  type        = string
  description = "Security group ID for Nextcloud ECS tasks"
}

variable "nextcloud_efs_sg_id" {
  type        = string
  description = "Security group ID for Nextcloud EFS mount targets"
}

variable "db_username" {
  type        = string
  description = "The username for the RDS database"
}

variable "docker_image" {
  type        = string
  description = "The Docker image to use for the Nextcloud container"
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

variable "aws_region" {
  type        = string
  description = "AWS region for CloudWatch Logs"
  default     = "us-east-1"
}

variable "task_cpu" {
  type        = string
  description = "Fargate task CPU units"
  default     = "512"
}

variable "task_memory" {
  type        = string
  description = "Fargate task memory (MiB)"
  default     = "1024"
}

variable "desired_count" {
  type        = number
  description = "Number of Nextcloud tasks to run"
  default     = 1
}

variable "admin_user" {
  type        = string
  description = "Nextcloud admin account created on first install"
  default     = "admin"
}

variable "admin_password" {
  type        = string
  description = "Nextcloud admin password created on first install"
  default     = "admin123"
  sensitive   = true
}

variable "permissions_boundary_arn" {
  type        = string
  description = "The ARN of the IAM permissions boundary (required in this account)"
}
