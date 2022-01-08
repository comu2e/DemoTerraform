# task defitnion template 
# コンテナ定義を呼び出す
data "template_file" "container_definitions" {
  template = jsonencode(local.ecs_tasks)
}

locals {
  ecs_tasks = [{
    name      = var.app_name // var.entry_container_name
    image     = "${local.account_id}.dkr.${local.region}.amazonaws.com/${var.app_name}:latest"
    command   = ["yarn", "start"]
    essential = true
    memory    = 256
    cpu       = 256

    portMappings = [{
      containerPort = "${var.entry_container_port}"
      hostPort      = "${var.entry_container_port}"
      protocol      = "tcp"
    }]

    linuxParameters = {
      initProcessEnabled = true
    }

    managedAgents = [{
      lastStartedAt = "2021-03-01T14:49:44.574000-06:00"
      name          = "ExecuteCommandAgent"
      lastStatus    = "RUNNING"
    }]
    mountPoints = [{
      sourceVolume  = "app-storage"
      containerPath = "/app"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-region        = local.region
        awslogs-group         = "${var.app_name}/frontend"
        awslogs-stream-prefix = "${var.app_name}-frontend"
      }
    }

    "environment" = [
      {
        name  = "PORT"
        value = "80"
      }
    ]

  }]
}

