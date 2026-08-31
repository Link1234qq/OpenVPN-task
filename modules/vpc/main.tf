locals {
  vpc_name = "${var.app_name}-${var.environment}-vpc"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.vpc_name
  cidr = var.vpc_cidr_block

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  manage_default_network_acl    = false
  manage_default_security_group = false
  manage_default_route_table    = false
  map_public_ip_on_launch       = true

  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  tags = {
    Name        = local.vpc_name
    Environment = var.environment
  }

  nat_gateway_tags = {
    Name = "${var.app_name}-${var.environment}-nat"
  }
}
