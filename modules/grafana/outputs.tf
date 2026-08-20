output "private_ip" {
  value       = module.ec2_instance.private_ip
  description = "Private IP of Grafana instance"
}

output "public_ip" {
  value       = module.ec2_instance.public_ip
  description = "Public IP of Grafana instance (egress only - SG allows VPN traffic only)"
}

output "instance_id" {
  value       = module.ec2_instance.id
  description = "EC2 instance ID of Grafana"
}

output "security_group_id" {
  value       = var.grafana_sg_id
  description = "Security group ID for Grafana"
}

output "grafana_url" {
  value       = "http://${module.ec2_instance.private_ip}:3000"
  description = "Grafana URL (accessible via VPN)"
}
