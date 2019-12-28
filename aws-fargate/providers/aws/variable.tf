variable "common" {
  type = map(string)

  default = {
    "default.region"  = "ap-northeast-1"
    "default.project" = "aws-fargate"
  }
}
