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
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"

  desired_count                     = 1
  health_check_grace_period_seconds = 15
  cluster                           = var.cluster

  task_definition = aws_ecs_task_definition.main.arn

  # GitHubActionsと整合性を取りたい場合は下記のようにrevisionを指定しなければよい
  # task_definition = "arn:aws:ecs:ap-northeast-1:${local.account_id}:task-definition/${aws_ecs_task_definition.main.family}"

  network_configuration {
    subnets          = var.placement_subnet
    security_groups  = var.sg_list
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.entry_container_name
    container_port   = var.entry_container_port
  }
}
# Log
resource "aws_cloudwatch_log_group" "main" {
  name              = "/${var.app_name}/ecs"
  retention_in_days = 7
}
