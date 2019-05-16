variable "common" {
  type = "map"

  default = {
    default.region  = "ap-northeast-1"
    default.project = "aws-fargate"
  }
}
