resource "aws_security_group" "ecs_api" {
  name        = lookup(var.ecs, "${terraform.workspace}.name", var.ecs["default.name"])
  description = "Security Group to ${lookup(var.ecs, "${terraform.workspace}.name", var.ecs["default.name"])}"
  vpc_id      = var.vpc["vpc_id"]

  tags = {
    Name = lookup(var.ecs, "${terraform.workspace}.name", var.ecs["default.name"])
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ecs_api_from_alb" {
  security_group_id        = aws_security_group.ecs_api.id
  type                     = "ingress"
  from_port                = "80"
  to_port                  = "80"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_alb.id
}

data "template_file" "user_data" {
  template = file("../../modules/aws/ecs/user-data/userdata.sh")

  vars = {
    cluster_name = aws_ecs_cluster.api_ecs_cluster.name
  }
}

resource "aws_instance" "ecs_instance" {
  ami                         = lookup(var.ecs, "${terraform.workspace}.ami", var.ecs["default.ami"])
  associate_public_ip_address = "false"
  instance_type = lookup(
    var.ecs,
    "${terraform.workspace}.instance_type",
    var.ecs["default.instance_type"],
  )
  subnet_id              = var.vpc["subnet_private_1a_id"]
  vpc_security_group_ids = [aws_security_group.ecs_api.id]

  tags = {
    Name = "${lookup(var.ecs, "${terraform.workspace}.name", var.ecs["default.name"])}-1a"
  }

  iam_instance_profile = aws_iam_instance_profile.ecs_instance.name
  monitoring           = true

  ebs_block_device {
    device_name = "/dev/xvda"
    volume_type = lookup(
      var.ecs,
      "${terraform.workspace}.volume_type",
      var.ecs["default.volume_type"],
    )
    volume_size = lookup(
      var.ecs,
      "${terraform.workspace}.volume_size",
      var.ecs["default.volume_size"],
    )
  }

  user_data = data.template_file.user_data.rendered

  lifecycle {
    ignore_changes = [ebs_block_device]
  }
}

resource "aws_cloudwatch_log_group" "ecs_api" {
  name = lookup(var.ecs, "${terraform.workspace}.name", var.ecs["default.name"])
}

resource "aws_ecs_cluster" "api_ecs_cluster" {
  name = lookup(var.ecs, "${terraform.workspace}.name", var.ecs["default.name"])
}

data "template_file" "api_template_file" {
  template = file("../../modules/aws/ecs/task/ecs-api.json")

  vars = {
    aws_region = lookup(
      var.common,
      "${terraform.workspace}.region",
      var.common["default.region"],
    )
    php_image_url   = var.ecr["php_image_url"]
    nginx_image_url = var.ecr["nginx_image_url"]
    aws_logs_group  = aws_cloudwatch_log_group.ecs_api.name
  }
}

resource "aws_ecs_task_definition" "api" {
  count                 = terraform.workspace != "prod" ? 1 : 0
  family                = lookup(var.ecs, "${terraform.workspace}.name", var.ecs["default.name"])
  network_mode          = "bridge"
  container_definitions = data.template_file.api_template_file.rendered
}

resource "aws_ecs_service" "api_ecs_service" {
  name            = lookup(var.ecs, "${terraform.workspace}.name", var.ecs["default.name"])
  cluster         = aws_ecs_cluster.api_ecs_cluster.id
  task_definition = aws_ecs_task_definition.api[0].arn
  desired_count = lookup(
    var.ecs,
    "${terraform.workspace}.service_desired_count",
    var.ecs["default.service_desired_count"],
  )
  iam_role = aws_iam_role.ecs_service_role.arn

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs.id
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [aws_alb_listener.ecs_alb]
}
