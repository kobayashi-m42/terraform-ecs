data "aws_iam_policy_document" "ecs_instance_trust_relationship" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "${terraform.workspace}-ecs-instance-role"
  path               = "/system/"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_instance_trust_relationship.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attach" {
  role       = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${terraform.workspace}-ecs-instance-profile"
  path = "/"
  role = "${aws_iam_role.ecs_instance_role.name}"
}

data "aws_iam_policy_document" "ecs_service_trust_relationship" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service_role" {
  name               = "${terraform.workspace}-ecs-service-role"
  path               = "/system/"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_service_trust_relationship.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_service_role_attach" {
  role       = "${aws_iam_role.ecs_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
