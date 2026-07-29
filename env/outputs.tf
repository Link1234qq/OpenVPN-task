output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "The IDs of the public subnets"
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "The IDs of the private subnets"
}

output "rds_sg_id" {
  value       = module.security.mysql_sg_id
  description = "The ID of the RDS security group"
}

output "rds_instance_endpoint" {
  value       = module.rds.rds_instance_endpoint
  description = "The endpoint of the RDS instance"
}

output "db_secret_arn" {
  value       = aws_secretsmanager_secret.db.arn
  description = "ARN of the Secrets Manager secret with database credentials"
}

output "db_secret_name" {
  value       = aws_secretsmanager_secret.db.name
  description = "Name of the Secrets Manager secret (for AWS CLI / console lookup)"
}

output "nextcloud_sg_id" {
  value       = module.security.nextcloud_sg_id
  description = "The ID of the Nextcloud security group"
}

output "nextcloud_public_ip" {
  value       = module.compute.public_ip
  description = "Public IP of the Nextcloud EC2 instance"
}

output "nextcloud_url" {
  value       = "http://${module.compute.public_ip}"
  description = "URL to open Nextcloud in the browser"
}

output "prometheus_private_ip" {
  value       = module.prometheus.private_ip
  description = "Private IP of Prometheus instance (in private subnet)"
}

output "grafana_public_ip" {
  value       = module.grafana.public_ip
  description = "Public IP of Grafana EC2 instance"
}

output "grafana_url" {
  value       = "http://${module.grafana.public_ip}:3000"
  description = "Grafana URL - login with admin / admin123"
}

output "openvpn_public_ip" {
  value       = module.vpn.public_ip
  description = "Elastic IP for OpenVPN (UDP 1194)"
}

output "openvpn_client_config_hint" {
  value       = "scp -i openvpn.pem ec2-user@${module.vpn.public_ip}:${module.vpn.client_config_path} ./client.ovpn"
  description = "Command to download the OpenVPN client profile"
}