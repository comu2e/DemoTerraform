variable "app_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

# ECSのsg
variable "sg_list" {
  description = "ECS security group.HTTP/HTTP security group is expected"
  type        = list(string)
}

# ecs  で 使用
variable "private_subnet_ids" {
  type = list(string)
}

# ALB target groupの設定
variable "target_group_arn" {
  type = string
}
variable "entry_container_port" {
  type = number
}
# cluster
variable "cluster_name" {
  type = string
}

# タスクに関連付けるIAM
variable "iam_role_task_execution_arn" {
  type = string
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  app_name   = var.app_name
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

