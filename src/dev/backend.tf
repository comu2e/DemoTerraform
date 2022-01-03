terraform {
  backend "s3" {
    # S3 bucket作成：aws s3 mb s3://tfstate-${var.app_name}
  }
}
