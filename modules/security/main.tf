module "nextcloud_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "~> 5.0"

  name        = "${var.app_name}-${var.environment}-nextcloud-sg"
  vpc_id      = var.vpc_id
  description = "Nextcloud web on port 80"

  ingress_cidr_blocks = [var.allowed_cidr]
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from admin IP"
      cidr_blocks = var.allowed_cidr
    }
  ]
}

module "mysql_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/mysql"
  version = "~> 5.0"

  name   = "${var.app_name}-${var.environment}-mysql-sg"
  vpc_id = var.vpc_id

  auto_ingress_rules = []

  ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = module.nextcloud_sg.security_group_id
    }
  ]
}

module "openvpn_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.app_name}-${var.environment}-openvpn-sg"
  vpc_id      = var.vpc_id
  description = "OpenVPN gateway"

  ingress_with_cidr_blocks = [
    {
      from_port   = 1194
      to_port     = 1194
      protocol    = "udp"
      description = "OpenVPN from admin IP"
      cidr_blocks = var.allowed_cidr
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH to OpenVPN server"
      cidr_blocks = var.allowed_cidr
    }
  ]

  egress_rules = ["all-all"]
}

module "prometheus_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.app_name}-${var.environment}-prometheus-sg"
  vpc_id      = var.vpc_id
  description = "Prometheus"

  ingress_with_source_security_group_id = [
    {
      from_port                = 9090
      to_port                  = 9090
      protocol                 = "tcp"
      description              = "Prometheus from Grafana"
      source_security_group_id = module.grafana_sg.security_group_id
    },
    {
      from_port                = 9090
      to_port                  = 9090
      protocol                 = "tcp"
      description              = "Prometheus from OpenVPN server (NAT)"
      source_security_group_id = module.openvpn_sg.security_group_id
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      description              = "SSH from OpenVPN server"
      source_security_group_id = module.openvpn_sg.security_group_id
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      description              = "SSH from Nextcloud"
      source_security_group_id = module.nextcloud_sg.security_group_id
    }
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      description = "Prometheus from VPC"
      cidr_blocks = var.prometheus_allowed_cidr
    },
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      description = "Prometheus from VPN clients"
      cidr_blocks = var.vpn_client_cidr
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from VPN clients"
      cidr_blocks = var.vpn_client_cidr
    }
  ]

  egress_rules = ["all-all"]
}

module "grafana_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.app_name}-${var.environment}-grafana-sg"
  vpc_id      = var.vpc_id
  description = "Grafana"

  ingress_with_cidr_blocks = [
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "Grafana from admin IP"
      cidr_blocks = var.allowed_cidr
    },
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "Grafana from VPN clients"
      cidr_blocks = var.vpn_client_cidr
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from admin IP"
      cidr_blocks = var.allowed_cidr
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from VPN clients"
      cidr_blocks = var.vpn_client_cidr
    }
  ]

  ingress_with_source_security_group_id = [
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      description              = "Grafana from OpenVPN server (NAT)"
      source_security_group_id = module.openvpn_sg.security_group_id
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      description              = "SSH from OpenVPN server"
      source_security_group_id = module.openvpn_sg.security_group_id
    },
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      description              = "Grafana from Nextcloud"
      source_security_group_id = module.nextcloud_sg.security_group_id
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      description              = "SSH from Nextcloud"
      source_security_group_id = module.nextcloud_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]
}

resource "aws_vpc_security_group_ingress_rule" "nextcloud_node_exporter" {
  security_group_id            = module.nextcloud_sg.security_group_id
  referenced_security_group_id = module.prometheus_sg.security_group_id
  from_port                    = 9100
  to_port                      = 9100
  ip_protocol                  = "tcp"
  description                  = "Node exporter from Prometheus"
}

resource "aws_vpc_security_group_ingress_rule" "nextcloud_http_vpn_clients" {
  security_group_id = module.nextcloud_sg.security_group_id
  cidr_ipv4         = var.vpn_client_cidr
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Nextcloud HTTP from VPN clients"
}

resource "aws_vpc_security_group_ingress_rule" "nextcloud_ssh_vpn_clients" {
  security_group_id = module.nextcloud_sg.security_group_id
  cidr_ipv4         = var.vpn_client_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Nextcloud SSH from VPN clients"
}

resource "aws_vpc_security_group_ingress_rule" "nextcloud_http_openvpn" {
  security_group_id            = module.nextcloud_sg.security_group_id
  referenced_security_group_id = module.openvpn_sg.security_group_id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "Nextcloud HTTP from OpenVPN server"
}

resource "aws_vpc_security_group_ingress_rule" "nextcloud_ssh_openvpn" {
  security_group_id            = module.nextcloud_sg.security_group_id
  referenced_security_group_id = module.openvpn_sg.security_group_id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "Nextcloud SSH from OpenVPN server"
}
