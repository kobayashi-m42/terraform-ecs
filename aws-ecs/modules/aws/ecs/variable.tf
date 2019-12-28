variable "ecs" {
  type = map(string)

  default = {
    "default.name"                  = "prod-ecs-api"
    "dev.name"                      = "dev-ecs-api"
    "default.instance_type"         = "t2.micro"
    "default.volume_size"           = "30"
    "default.volume_type"           = "gp2"
    "default.ami"                   = "ami-084cb340923dc7101"
    "default.service_desired_count" = "1"
  }
}

variable "common" {
  type = map(string)

  default = {}
}

variable "vpc" {
  type = map(string)

  default = {}
}

variable "ecr" {
  type = map(string)

  default = {}
}

data "aws_elb_service_account" "aws_elb_service_account" {}
