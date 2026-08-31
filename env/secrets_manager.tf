resource "random_password" "db" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.app_name}/${var.environment}/db-credentials"
  description             = "RDS and application database credentials for ${var.app_name} ${var.environment}"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.app_name}-${var.environment}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
  })
}

locals {
  db_credentials = jsondecode(aws_secretsmanager_secret_version.db.secret_string)
}
