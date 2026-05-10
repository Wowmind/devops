# ECR- image registry for storing container images
resource "aws_ecr_repository" "devops_test" {
  name                 = local.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, { Name = local.name })
}

resource "aws_ecr_lifecycle_policy" "devops_test" {
  repository = aws_ecr_repository.devops_test.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

# CloudWatch — Log Group, Alarms, Dashboard

resource "aws_cloudwatch_log_group" "devops_test" {
  name              = "/ecs/${local.name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, { Name = "/ecs/${local.name}" })
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU > 80% for 2 consecutive minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.devops_test.name
    ServiceName = aws_ecs_service.devops_test.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${local.name}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS Memory > 80% for 2 consecutive minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.devops_test.name
    ServiceName = aws_ecs_service.devops_test.name
  }

  tags = local.common_tags
}

# ECS — Security Group
resource "aws_security_group" "ecs" {
  name        = "${local.name}-ecs-sg"
  description = "Allow inbound on container port, all outbound"
  vpc_id      = aws_vpc.devops_test.id

  ingress {
    description = "Container port"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name}-ecs-sg" })
}


# ECS — Cluster, Task Definition, Service

resource "aws_ecs_cluster" "devops_test" {
  name = "${local.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, { Name = "${local.name}-cluster" })
}

resource "aws_ecs_task_definition" "devops_test" {
  family                   = "${local.name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([{
    name      = local.name
    image     = "${aws_ecr_repository.devops_test.repository_url}:${var.image_tag}"
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [
      { name = "ENVIRONMENT", value = var.environment },
      { name = "APP_VERSION", value = var.image_tag },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.devops_test.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "wget -qO- http://localhost:${var.container_port}/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 15
    }
  }])

  tags = local.common_tags

  depends_on = [aws_cloudwatch_log_group.devops_test]
}

resource "aws_ecs_service" "devops_test" {
  name            = "${local.name}-service"
  cluster         = aws_ecs_cluster.devops_test.id
  task_definition = aws_ecs_task_definition.devops_test.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = local.common_tags

  depends_on = [aws_iam_role_policy_attachment.task_execution]
}
