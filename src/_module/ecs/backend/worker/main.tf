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


variable "entry_container_name" {
  type        = string
  description = "Entrypoint container name ex:nginx or worker is expected"
}
variable "entry_container_port" {
  type        = number
  description = "Entrypoint container port number ex:nginx or worker port is expected"
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

data "template_file" "container_definitions" {
  template = file(abspath("../_module/ecs/backend/worker/worker-container.json"))
  # templateのjsonファイルに値を渡す
  vars = {
    tag                  = "latest"
    name                 = var.app_name
    entry_container_name = var.entry_container_name
    entry_container_port = 6379
    account_id           = local.account_id
    region               = local.region
  }
}

# タスク定義
resource "aws_ecs_task_definition" "main" {
  family = "${var.app_name}-${var.entry_container_name}"

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

  name                   = "${var.app_name}-${var.entry_container_name}"
  enable_execute_command = true

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

  #   load_balancer {
  #     target_group_arn = var.target_group_arn
  #     container_name   = var.entry_container_name
  #     container_port   = var.entry_container_port
  #   }
}
# Log
resource "aws_cloudwatch_log_group" "main" {
  name              = "/${var.app_name}/worker"
  retention_in_days = 7
}

# Task Schedule
resource "aws_cloudwatch_event_rule" "schedule" {
  description         = "run php artisan schedule every minutes"
  is_enabled          = true
  name                = "schedule_every_minutes"
  schedule_expression = "cron(* * * * ? *)"
}

data "template_file" "php_artisan_schedule" {
  template = file(abspath("../_module/ecs/backend/worker/ecs_container_overrides.json"))

  vars = {
    command = "schedule:run"
    # option  = "--tries=1"
  }
}
variable "cluster_arn" {
  type = string
}
variable "vpc_id" {
  type = string
}

resource "aws_cloudwatch_event_target" "schedule" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  arn       = var.cluster_arn
  target_id = "schedule"
  role_arn  = aws_iam_role.ecs_events_run_task.arn
  input     = data.template_file.php_artisan_schedule.rendered
  ecs_target {
    launch_type         = "FARGATE"
    task_count          = 1
    task_definition_arn = replace(aws_ecs_task_definition.main.arn, "/:[0-9]+$/", "")
    network_configuration {
      security_groups = var.sg
      subnets         = var.placement_subnet
    }
  }
}

data "aws_iam_policy_document" "events_assume_role" {
  statement {
    sid     = "CloudWatchEvents"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["events.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "ecs_events_run_task" {
  name               = "${var.app_name}-ECSEventsRunTask"
  assume_role_policy = data.aws_iam_policy_document.events_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_events_run_task" {
  role       = aws_iam_role.ecs_events_run_task.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}
