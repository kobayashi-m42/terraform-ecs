variable "fargate" {
  type = "map"

  default = {
    default.name                  = "prod-fargate-api"
    dev.name                      = "dev-fargate-api"
    default.service_desired_count = "1"
    default.task_cpu              = "256"
    default.task_memory           = "512"
  }
}

variable "common" {
  type = "map"

  default = {}
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
