# =========================================================
# Task Definition
# =========================================================
resource "aws_ecs_task_definition" "frontend" {
  family = "${var.app_name}-frontend"

  # データプレーンの選択
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc" # ECSタスクのネットワークドライバ  :Fargateを使用する場合は"awsvpc"
  cpu                      = 256      # ECSタスクが使用可能なリソースの上限 (タスク内のコンテナはこの上限内に使用するリソースを収める必要があり、メモリが上限に達した場合OOM Killer にタスクがキルされる
  memory                   = 512

  # 起動するコンテナの定義 (nginx, app)
  container_definitions = data.template_file.container_definitions.rendered

  volume {
    name = "app-storage"
  }

  # 実行するuser の設定
  task_role_arn      = var.iam_role_task_execution_arn
  execution_role_arn = var.iam_role_task_execution_arn
}

# ========================================================
# ECS
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
# ========================================================
resource "aws_ecs_service" "frontend" {
  # depends_on = [aws_lb_listener_rule.frontend]
  name                   = "${var.app_name}-frontend"
  cluster                = var.cluster_name # clusterの指定
  enable_execute_command = true             # SSMの有効化

  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  # 以下の値を task の数を設定しないと、serviceの内のタスクが0になり動作しない。
  desired_count                     = 1
  health_check_grace_period_seconds = 15

  # task_definition = aws_ecs_task_definition.frontend.arn
  # GitHubActionsと整合性を取りたい場合は下記のようにrevisionを指定しなければよい
  task_definition = "arn:aws:ecs:ap-northeast-1:${local.account_id}:task-definition/${aws_ecs_task_definition.frontend.family}"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = var.sg_list
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.app_name
    #frontendのポートに合わせる必要あり。
    container_port   = 3000 
  }

  # cloudmapで使用
  #  service_registries {
  #    registry_arn = var.service_registries_arn
  #  }
}

# =========================================================
# CloudWatch Logsの出力先（Log Group）
#
# Logの設定自体はjson。あくまでwebとappの出力先を指定
# =========================================================
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/${local.app_name}/frontend"
  retention_in_days = 7
}
