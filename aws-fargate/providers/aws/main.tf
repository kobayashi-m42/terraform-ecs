module "vpc" {
  source = "../../modules/aws/vpc"
  common = var.common
}

module "ecr" {
  source = "../../modules/aws/ecr"
}

module "fargate" {
  source = "../../modules/aws/fargate"
  common = var.common
  vpc    = module.vpc.vpc
  ecr    = module.ecr.ecr
}
