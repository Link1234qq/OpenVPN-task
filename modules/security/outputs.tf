output "mysql_sg_id" {
  value = module.mysql_security_group.security_group_id
}

output "nextcloud_alb_sg_id" {
  value = module.nextcloud_alb_sg.security_group_id
}

output "nextcloud_ecs_sg_id" {
  value = module.nextcloud_ecs_sg.security_group_id
}

output "nextcloud_efs_sg_id" {
  value = module.nextcloud_efs_sg.security_group_id
}

# Backward-compatible alias for root outputs
output "nextcloud_sg_id" {
  value = module.nextcloud_alb_sg.security_group_id
}

output "prometheus_sg_id" {
  value = module.prometheus_sg.security_group_id
}

output "grafana_sg_id" {
  value = module.grafana_sg.security_group_id
}

output "openvpn_sg_id" {
  value = module.openvpn_sg.security_group_id
}
