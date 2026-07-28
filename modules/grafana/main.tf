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

  name = "${var.app_name}-${var.environment}-grafana"

  ami                        = data.aws_ami.amazon_linux_2023.id
  instance_type              = var.instance_type
  subnet_id                  = var.public_subnets[0]
  vpc_security_group_ids     = [var.grafana_sg_id]
  create_security_group      = false
  associate_public_ip_address = true
  monitoring                 = true
  key_name                   = var.key_name

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    docker_image              = var.docker_image
    grafana_admin_password    = var.grafana_admin_password
    prometheus_ip             = var.prometheus_private_ip
  })

  user_data_replace_on_change = false

  tags = {
    Name        = "${var.app_name}-${var.environment}-grafana"
    Environment = var.environment
  }
}
