module "vpc" {
  source = "../../modules/aws/vpc"
  common = "${var.common}"
}

module "ecr" {
  source = "../../modules/aws/ecr"
}

module "ecs" {
  source = "../../modules/aws/ecs"
  vpc    = "${module.vpc.vpc}"
  ecr    = "${module.ecr.ecr}"
}
