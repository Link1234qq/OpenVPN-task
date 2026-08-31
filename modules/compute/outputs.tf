output "alb_dns_name" {
  value       = aws_lb.nextcloud.dns_name
  description = "DNS name of the Nextcloud Application Load Balancer"
}

output "alb_arn" {
  value       = aws_lb.nextcloud.arn
  description = "ARN of the Nextcloud ALB"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.nextcloud.name
  description = "Name of the ECS cluster running Nextcloud"
}

output "ecs_service_name" {
  value       = aws_ecs_service.nextcloud.name
  description = "Name of the ECS Fargate service"
}
