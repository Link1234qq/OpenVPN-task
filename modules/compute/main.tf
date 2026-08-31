locals {
  name_prefix = "${var.app_name}-${var.environment}"
  db_name     = "${var.app_name}${var.environment}database"
}

resource "aws_cloudwatch_log_group" "nextcloud" {
  name              = "/ecs/${local.name_prefix}-nextcloud"
  retention_in_days = 7

  tags = {
    Name        = "${local.name_prefix}-nextcloud-logs"
    Environment = var.environment
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name                 = "${local.name_prefix}-nextcloud-ecs-execution"
  permissions_boundary = var.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name                 = "${local.name_prefix}-nextcloud-ecs-task"
  permissions_boundary = var.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "ecs_efs" {
  name = "${local.name_prefix}-nextcloud-efs"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite"
      ]
      Resource = aws_efs_file_system.nextcloud.arn
      Condition = {
        StringEquals = {
          "elasticfilesystem:AccessPointArn" = [
            aws_efs_access_point.data.arn,
            aws_efs_access_point.config.arn
          ]
        }
      }
    }]
  })
}

resource "aws_efs_file_system" "nextcloud" {
  creation_token = "${local.name_prefix}-nextcloud"
  encrypted      = true

  tags = {
    Name        = "${local.name_prefix}-nextcloud-efs"
    Environment = var.environment
  }
}

// Only user data and config live on EFS. Mounting the whole webroot makes the
// image entrypoint copy ~15k files over NFS on every cold start, which outlasts
// the health check grace period and leaves a stale init lock on the volume.
resource "aws_efs_access_point" "data" {
  file_system_id = aws_efs_file_system.nextcloud.id

  root_directory {
    path = "/nextcloud-data"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "755"
    }
  }

  posix_user {
    gid = 33
    uid = 33
  }

  tags = {
    Name        = "${local.name_prefix}-nextcloud-data"
    Environment = var.environment
  }
}

resource "aws_efs_access_point" "config" {
  file_system_id = aws_efs_file_system.nextcloud.id

  root_directory {
    path = "/nextcloud-config"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "755"
    }
  }

  posix_user {
    gid = 33
    uid = 33
  }

  tags = {
    Name        = "${local.name_prefix}-nextcloud-config"
    Environment = var.environment
  }
}

resource "aws_efs_mount_target" "nextcloud" {
  count = length(var.private_subnets)

  file_system_id  = aws_efs_file_system.nextcloud.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [var.nextcloud_efs_sg_id]
}

resource "aws_ecs_cluster" "nextcloud" {
  name = "${local.name_prefix}-nextcloud"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Name        = "${local.name_prefix}-nextcloud"
    Environment = var.environment
  }
}

resource "aws_lb" "nextcloud" {
  name               = "${local.name_prefix}-nextcloud"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.nextcloud_alb_sg_id]
  subnets            = var.private_subnets

  tags = {
    Name        = "${local.name_prefix}-nextcloud-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "nextcloud" {
  name        = "${local.name_prefix}-nextcloud"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    path                = "/status.php"
    # Health checks arrive with the target IP as Host, which Nextcloud rejects as
    # an untrusted domain with 400 - still proof that the app is serving
    matcher = "200,400"
  }

  tags = {
    Name        = "${local.name_prefix}-nextcloud-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "nextcloud" {
  load_balancer_arn = aws_lb.nextcloud.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nextcloud.arn
  }
}

resource "aws_ecs_task_definition" "nextcloud" {
  family                   = "${local.name_prefix}-nextcloud"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  volume {
    name = "nextcloud-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.nextcloud.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.data.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "nextcloud-config"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.nextcloud.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.config.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name      = "nextcloud"
    image     = var.docker_image
    essential = true

    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]

    environment = [
      { name = "MYSQL_HOST", value = var.db_host },
      { name = "MYSQL_DATABASE", value = local.db_name },
      { name = "MYSQL_USER", value = var.db_username },
      { name = "MYSQL_PASSWORD", value = var.db_password },
      { name = "NEXTCLOUD_ADMIN_USER", value = var.admin_user },
      { name = "NEXTCLOUD_ADMIN_PASSWORD", value = var.admin_password },
      { name = "NEXTCLOUD_TRUSTED_DOMAINS", value = aws_lb.nextcloud.dns_name }
    ]

    mountPoints = [
      {
        sourceVolume  = "nextcloud-data"
        containerPath = "/var/www/html/data"
        readOnly      = false
      },
      {
        sourceVolume  = "nextcloud-config"
        containerPath = "/var/www/html/config"
        readOnly      = false
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.nextcloud.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = {
    Name        = "${local.name_prefix}-nextcloud"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "nextcloud" {
  name            = "${local.name_prefix}-nextcloud"
  cluster         = aws_ecs_cluster.nextcloud.id
  task_definition = aws_ecs_task_definition.nextcloud.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.nextcloud_ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nextcloud.arn
    container_name   = "nextcloud"
    container_port   = 80
  }

  health_check_grace_period_seconds = 600

  depends_on = [
    aws_lb_listener.nextcloud,
    aws_efs_mount_target.nextcloud
  ]

  tags = {
    Name        = "${local.name_prefix}-nextcloud"
    Environment = var.environment
  }
}
