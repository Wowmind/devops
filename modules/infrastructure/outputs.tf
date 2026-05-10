output "ecr_repository_url" {
  description = "Full URI of the ECR repository — used by CI/CD to push images"
  value       = aws_ecr_repository.devops_test.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.devops_test.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.devops_test.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group receiving all container logs"
  value       = aws_cloudwatch_log_group.devops_test.name
}

output "cloudwatch_dashboard_url" {
  description = "Direct link to the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.devops_test.dashboard_name}"
}

output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = aws_vpc.devops_test.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}
