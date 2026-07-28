output "private_ip" {
  value       = module.ec2_instance.private_ip
  description = "Private IP of Prometheus instance"
}

output "instance_id" {
  value       = module.ec2_instance.id
  description = "EC2 instance ID of Prometheus"
}

output "security_group_id" {
  value       = var.prometheus_sg_id
  description = "Security group ID for Prometheus"
}
