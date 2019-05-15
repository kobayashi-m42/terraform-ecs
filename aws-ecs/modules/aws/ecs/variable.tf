variable "ecs" {
  type = "map"

  default = {
    region                        = "ap-northeast-1"
    default.name                  = "prod-ecs-api"
    dev.name                      = "dev-ecs-api"
    default.instance_type         = "t2.micro"
    default.volume_size           = "30"
    default.volume_type           = "gp2"
    default.ami                   = "ami-084cb340923dc7101"
    default.service_desired_count = 1
  }
}

variable "vpc" {
  type = "map"

  default = {}
}

variable "ecr" {
  type = "map"

  default = {}
}

data "aws_elb_service_account" "aws_elb_service_account" {}
