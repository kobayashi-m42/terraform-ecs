resource "aws_security_group" "fargate_api" {
  name = lookup(
    var.fargate,
    "${terraform.workspace}.name",
    var.fargate["default.name"],
  )
  description = "Security Group to ${lookup(
    var.fargate,
    "${terraform.workspace}.name",
    var.fargate["default.name"],
  )}"
  vpc_id = var.vpc["vpc_id"]

  tags = {
    Name = lookup(
      var.fargate,
      "${terraform.workspace}.name",
      var.fargate["default.name"],
    )
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "fargate_api_from_alb" {
  security_group_id        = aws_security_group.fargate_api.id
  type                     = "ingress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.fargate_api_alb.id
}

resource "aws_cloudwatch_log_group" "fargate_api" {
  name = lookup(
    var.fargate,
    "${terraform.workspace}.name",
    var.fargate["default.name"],
  )
}

resource "aws_ecs_cluster" "api_fargate_cluster" {
  name = lookup(
    var.fargate,
    "${terraform.workspace}.name",
    var.fargate["default.name"],
  )
}

data "template_file" "api_fargate_template_file" {
  template = file("../../modules/aws/fargate/task/fargate-api.json")

  vars = {
    aws_region = lookup(
      var.common,
      "${terraform.workspace}.region",
      var.common["default.region"],
    )
    php_image_url   = var.ecr["php_image_url"]
    nginx_image_url = var.ecr["nginx_image_url"]
    aws_logs_group  = aws_cloudwatch_log_group.fargate_api.name
  }
}

resource "aws_ecs_task_definition" "api_fargate" {
  family = lookup(
    var.fargate,
    "${terraform.workspace}.name",
    var.fargate["default.name"],
  )
  network_mode          = "awsvpc"
  container_definitions = data.template_file.api_fargate_template_file.rendered
  cpu = lookup(
    var.fargate,
    "${terraform.workspace}.task_cpu",
    var.fargate["default.task_cpu"],
  )
  memory = lookup(
    var.fargate,
    "${terraform.workspace}.task_memory",
    var.fargate["default.task_memory"],
  )
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution_role.arn

  depends_on = [aws_cloudwatch_log_group.fargate_api]
}

resource "aws_ecs_service" "api_fargate_service" {
  name = lookup(
    var.fargate,
    "${terraform.workspace}.name",
    var.fargate["default.name"],
  )
  cluster         = aws_ecs_cluster.api_fargate_cluster.id
  task_definition = aws_ecs_task_definition.api_fargate.arn
  desired_count = lookup(
    var.fargate,
    "${terraform.workspace}.service_desired_count",
    var.fargate["default.service_desired_count"],
  )
  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = aws_alb_target_group.fargate_api_blue.id
    container_name   = "nginx"
    container_port   = 80
  }

  network_configuration {
    subnets = [var.vpc["subnet_private_1a_id"], var.vpc["subnet_private_1c_id"], var.vpc["subnet_private_1d_id"]]

    security_groups = [
      aws_security_group.fargate_api.id,
    ]
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer,
    ]
  }

  depends_on = [aws_alb_listener.fargate_alb]
}
