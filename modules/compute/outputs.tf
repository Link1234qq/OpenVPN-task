output "public_ip" {
  value       = module.ec2_instance.public_ip
  description = "Public IP of the Nextcloud EC2 instance"
}

output "private_ip" {
  value       = module.ec2_instance.private_ip
  description = "Private IP for Prometheus scrape targets"
}

output "instance_id" {
  value       = module.ec2_instance.id
  description = "EC2 instance ID"
}
