variable "app_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "db_sg_id" {
  type        = string
  description = "RDB security group"
}
variable "private_subnet_ids" {
  type = list(string)
}
# 事前にSSMでパラメータを設定しておく
data "aws_ssm_parameter" "db_username" {
  name = "/${var.app_name}/DB_USERNAME"
}
data "aws_ssm_parameter" "db_name" {
  name = "/${var.app_name}/DB_NAME"
}
data "aws_ssm_parameter" "db_password" {
  name = "/${var.app_name}/DB_PASSWORD"
}
locals {
  db_username = data.aws_ssm_parameter.db_username.value
  db_password = data.aws_ssm_parameter.db_password.value
  db_name     = data.aws_ssm_parameter.db_name.value
}
