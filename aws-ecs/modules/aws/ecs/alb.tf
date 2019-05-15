resource "aws_security_group" "ecs_alb" {
  name        = "${lookup(var.ecs, "${terraform.env}.name", var.ecs["default.name"])}-alb"
  description = "Security Group to ${lookup(var.ecs, "${terraform.env}.name", var.ecs["default.name"])}-alb"
  vpc_id      = "${lookup(var.vpc, "vpc_id")}"

  tags {
    Name = "${lookup(var.ecs, "${terraform.env}.name", var.ecs["default.name"])}-alb"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ecs_alb" {
  security_group_id = "${aws_security_group.ecs_alb.id}"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_s3_bucket" "ecs_api_alb_logs" {
  bucket        = "${lookup(var.ecs, "${terraform.env}.name", var.ecs["default.name"])}-alb-logs"
  force_destroy = true
}

data "aws_iam_policy_document" "put_ecs_api_alb_logs_policy" {
  "statement" {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.ecs_api_alb_logs.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.aws_elb_service_account.id}"]
    }
  }
}

resource "aws_s3_bucket_policy" "fargate_api" {
  bucket = "${aws_s3_bucket.ecs_api_alb_logs.id}"
  policy = "${data.aws_iam_policy_document.put_ecs_api_alb_logs_policy.json}"
}

resource "aws_alb" "ecs_alb" {
  name                       = "${lookup(var.ecs, "${terraform.env}.name", var.ecs["default.name"])}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = ["${aws_security_group.ecs_alb.id}"]
  subnets                    = ["${var.vpc["subnet_public_1a_id"]}", "${var.vpc["subnet_public_1c_id"]}", "${var.vpc["subnet_public_1d_id"]}"]
  enable_deletion_protection = false

  access_logs {
    enabled = true
    bucket  = "${aws_s3_bucket.ecs_api_alb_logs.bucket}"
  }

  tags {
    Name = "${lookup(var.ecs, "${terraform.env}.name", var.ecs["default.name"])}-alb"
  }
}

resource "aws_alb_target_group" "ecs" {
  name     = "${lookup(var.ecs, "${terraform.env}.name", var.ecs["default.name"])}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${lookup(var.vpc, "vpc_id")}"

  health_check {
    path                = "/api/statuses"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    interval            = 20
    matcher             = 200
  }
}

resource "aws_alb_listener" "ecs_alb" {
  load_balancer_arn = "${aws_alb.ecs_alb.id}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.ecs.id}"
    type             = "forward"
  }
}
