variable "project" {
  description = "Project name — used as a prefix across all resource names"
  type        = string
  default = "devops-challenge"
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging)"
  type        = string
  default = "prod"
}

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to place public subnets in"
  type        = list(string)
  default = [ "us-east-1a", "us-east-1b" ]
}

variable "image_tag" {
  description = "Docker image tag to deploy (set per commit SHA by CI/CD)"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU — minimum)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MB (512 — minimum)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of ECS task replicas"
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "Days to retain logs in CloudWatch"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags merged onto all resources"
  type        = map(string)
  default     = {}
}
