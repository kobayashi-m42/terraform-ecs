variable "profile" {}

provider "aws" {
  version = "=2.4.0"
  profile = "${var.profile}"
  region  = "${lookup(var.common, "${terraform.env}.region", var.common["default.region"])}"
}
