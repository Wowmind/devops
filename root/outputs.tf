output "ecr_repository_url" {
  description = "Push Docker images to devops_test URI"
  value       = module.infrastructure.ecr_repository_url
}

//ecs
output "ecs_cluster_name" {
  description = "ECS cluster name — used in CI/CD deploy step"
  value       = module.infrastructure.ecs_cluster_name
}
output "ecs_service_name" {
  description = "ECS service name — used in CI/CD deploy step"
  value       = module.infrastructure.ecs_service_name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for container logs"
  value       = module.infrastructure.cloudwatch_log_group
}

output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = module.infrastructure.vpc_id
}
