terraform {
  backend "s3" {
    bucket = "tfstate-housebokan-dev"
    key    = "dev/terraform.tfstate"
    region = "ap-northeast-1"
  }
}
