variable "project" {
  description = "Project name used as a prefix across all resource names"
  type        = string
  default     = "devops-challenge"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region to deploy all resources into"
  type        = string
  default     = "us-east-1"
}

variable "image_tag" {
  description = "Docker image tag — overridden by CI/CD on each deploy"
  type        = string
  default     = "latest"
}
