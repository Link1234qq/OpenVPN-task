data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name = "${var.app_name}-${var.environment}-openvpn"

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = length(var.public_subnets) > 1 ? var.public_subnets[1] : var.public_subnets[0]
  vpc_security_group_ids      = [var.openvpn_sg_id]
  create_security_group       = false
  associate_public_ip_address = true
  create_eip                  = true
  monitoring                  = true
  key_name                    = var.key_name

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    vpn_client_cidr = var.vpn_client_cidr
    vpc_cidr_block  = var.vpc_cidr_block
  })

  user_data_replace_on_change = true

  tags = {
    Name        = "${var.app_name}-${var.environment}-openvpn"
    Environment = var.environment
  }
}
