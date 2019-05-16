module "vpc" {
  source = "../../modules/aws/vpc"
  common = "${var.common}"
}
