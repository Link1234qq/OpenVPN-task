output "rds_instance_endpoint" {
  value       = aws_db_instance.this.endpoint
  description = "RDS endpoint (host:port)"
}

output "rds_instance_address" {
  value       = aws_db_instance.this.address
  description = "RDS hostname without port (use for MYSQL_HOST)"
}
