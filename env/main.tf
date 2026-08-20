data "aws_caller_identity" "current" {}

locals {
  permissions_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/eo_role_boundary"
}

module "vpc" {
  source          = "../modules/vpc"
  app_name        = var.app_name
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  vpc_cidr_block  = var.vpc_cidr_block
  environment     = var.environment
}

module "security" {
  source                  = "../modules/security"
  app_name                = var.app_name
  vpc_id                  = module.vpc.vpc_id
  environment             = var.environment
  allowed_cidr            = var.allowed_cidr
  vpn_client_cidr         = var.vpn_client_cidr
  prometheus_allowed_cidr = var.vpc_cidr_block
}

module "rds" {
  source        = "../modules/rds"
  app_name      = var.app_name
  db_subnet_ids = module.vpc.private_subnets
  rds_sg_id     = module.security.mysql_sg_id
  environment   = var.environment
  db_username   = local.db_credentials.username
  db_password   = local.db_credentials.password
}

module "compute" {
  source = "../modules/compute"

  app_name                 = var.app_name
  environment              = var.environment
  vpc_id                   = module.vpc.vpc_id
  private_subnets          = module.vpc.private_subnets
  nextcloud_alb_sg_id      = module.security.nextcloud_alb_sg_id
  nextcloud_ecs_sg_id      = module.security.nextcloud_ecs_sg_id
  nextcloud_efs_sg_id      = module.security.nextcloud_efs_sg_id
  docker_image             = var.docker_image
  db_username              = local.db_credentials.username
  db_password              = local.db_credentials.password
  db_host                  = module.rds.rds_instance_address
  permissions_boundary_arn = local.permissions_boundary_arn

  depends_on = [module.rds]
}

module "prometheus" {
  source = "../modules/prometheus"

  app_name         = var.app_name
  environment      = var.environment
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  prometheus_sg_id = module.security.prometheus_sg_id
  key_name         = var.key_name

  depends_on = [module.compute]
}

module "grafana" {
  source = "../modules/grafana"

  app_name              = var.app_name
  environment           = var.environment
  public_subnets        = module.vpc.public_subnets
  grafana_sg_id         = module.security.grafana_sg_id
  prometheus_private_ip = module.prometheus.private_ip
  key_name              = var.key_name

  depends_on = [module.prometheus]
}

module "vpn" {
  source = "../modules/vpn"

  app_name        = var.app_name
  environment     = var.environment
  public_subnets  = module.vpc.public_subnets
  openvpn_sg_id   = module.security.openvpn_sg_id
  vpc_cidr_block  = var.vpc_cidr_block
  vpn_client_cidr = var.vpn_client_cidr
  key_name        = var.key_name
}
