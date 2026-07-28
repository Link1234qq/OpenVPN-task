output "public_ip" {
  value       = module.ec2_instance.public_ip
  description = "Elastic IP attached to the OpenVPN instance"
}

output "instance_id" {
  value       = module.ec2_instance.id
  description = "OpenVPN EC2 instance ID"
}

output "client_config_path" {
  value       = "/home/ec2-user/client.ovpn"
  description = "Path to the OpenVPN client profile on the server (copy via SCP/SSH)"
}
