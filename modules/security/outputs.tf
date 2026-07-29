output "mysql_sg_id" {
  value = module.mysql_security_group.security_group_id
}

output "nextcloud_sg_id" {
  value = module.nextcloud_sg.security_group_id
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
