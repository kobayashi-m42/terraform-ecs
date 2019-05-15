module "vpc" {
  source = "../../modules/aws/vpc"
  common = "${var.common}"
}

module "ecr" {
  source = "../../modules/aws/ecr"
}
