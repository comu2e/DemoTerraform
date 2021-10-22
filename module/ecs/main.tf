variable "app_name" {
  type = string
}
variable "cluster" {
  description = "ECS Cluster"
  type        = string
}
variable "aws_iam_role_task_exection_arn" {
  description = "ECS Task execution IAM role arn"
  type        = string
}
# public subnetに配置するか、private subnetに配置するかを制御する
variable "placement_subnet" {
  description = "ECS placement subnet.Public subnet or Private subnet is expected."
  type        = list(string)
}

variable "sg" {
  description = "ECS security group.HTTP/HTTP security group is expected"
  type        = list(string)
}

variable "target_group_arn" {
  type = string
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}
data "template_file" "container_definitions" {
  template = file("./ecs/container_definitions.json")
  # templateのjsonファイルに値を渡す
  vars = {
    tag        = "latest"
    name       = var.app_name
    account_id = local.account_id
    region     = local.region
  }
}
# タスク定義
resource "aws_ecs_task_definition" "main" {
  family = var.app_name

  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = data.template_file.container_definitions.rendered

  volume {
    name = "app-storage"
  }

  task_role_arn      = var.aws_iam_role_task_exection_arn
  execution_role_arn = var.aws_iam_role_task_exection_arn
}
# サービス
resource "aws_ecs_service" "main" {
  #   depends_on = [aws_lb_listener_rule.main]

  name = var.app_name

  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  desired_count = 1

  cluster = var.cluster

  task_definition = aws_ecs_task_definition.main.arn

  # GitHubActionsと整合性を取りたい場合は下記のようにrevisionを指定しなければよい
  # task_definition = "arn:aws:ecs:ap-northeast-1:${local.account_id}:task-definition/${aws_ecs_task_definition.main.family}"

  network_configuration {
    subnets          = var.placement_subnet
    security_groups  = var.sg
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "nginx"
    container_port   = 80
  }
}
# Log
resource "aws_cloudwatch_log_group" "main" {
  name              = "/${var.app_name}/ecs"
  retention_in_days = 7
}
