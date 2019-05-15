output "vpc" {
  value = "${module.vpc.vpc}"
}

output "ecr" {
  value = "${module.ecr.ecr}"
}
