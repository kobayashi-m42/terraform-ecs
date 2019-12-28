variable "profile" {
}

provider "aws" {
  version = "=2.43.0"
  profile = var.profile
  region = lookup(
    var.common,
    "${terraform.workspace}.region",
    var.common["default.region"],
  )
}
