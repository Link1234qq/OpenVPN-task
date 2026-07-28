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

  name = "${var.app_name}-${var.environment}-prometheus"

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnets[0]
  vpc_security_group_ids      = [var.prometheus_sg_id]
  create_security_group       = false
  associate_public_ip_address = false
  monitoring                  = true
  key_name                    = var.key_name

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    docker_image       = var.docker_image
    prometheus_config  = templatefile("${path.module}/templates/prometheus.yml.tpl", {
      nextcloud_ip = var.nextcloud_private_ip
    })
  })

  user_data_replace_on_change = false

  tags = {
    Name        = "${var.app_name}-${var.environment}-prometheus"
    Environment = var.environment
  }
}
