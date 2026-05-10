module "infrastructure" {
  source = "../modules/infrastructure"

  project            = var.project
  environment        = var.environment
  aws_region         = var.aws_region
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  image_tag          = var.image_tag
  task_cpu           = 256
  task_memory        = 512
  desired_count      = 1
  log_retention_days = 7
  tags               = local.common_tags
}
