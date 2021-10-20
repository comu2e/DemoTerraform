provider "aws" {
  region = "ap-northeast-1"
  # version = "3.0"
}
terraform {
  required_version = "1.0.8"
}

module "ecs_endpoint" {
  depends_on = [aws_lb_listener_rule.main]

  source              = "./endpoint"
  app_name            = var.app_name
  vpc_id              = module.network.vpc_id
  vpc_cidr            = var.vpc_cidr
  private_route_table = module.network.route_table_private
  private_subnet      = module.network.private_subnet_ids
}

module "iam" {
  source   = "./iam"
  app_name = var.app_name
}
module "compute" {
  source           = "./compute"
  app_name         = var.app_name
  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.private_subnet_ids[0]

}
module "network" {
  source               = "./network"
  app_name             = var.app_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}
# SecurityGroup
resource "aws_security_group" "http" {
  vpc_id = module.network.vpc_id

  name        = "${var.app_name}-main"
  description = "${var.app_name}-main"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.app_name}-main"
  }
}

resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.http.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
}

#ECS
####
#Cluster
####
resource "aws_ecs_cluster" "main" {
  name = var.app_name
}

module "ecs_app" {
  source                         = "./ecs"
  app_name                       = var.app_name
  cluster                        = aws_ecs_cluster.main.name
  aws_iam_role_task_exection_arn = module.iam.aws_iam_role_task_exection_arn
  target_group_arn               = aws_lb_target_group.main.arn
  placement_subnet               = module.network.public_subnet_ids
  endpoint_sg                    = [module.ecs_endpoint.endpoint_sg_id]
}
resource "aws_lb" "main" {
  load_balancer_type = "application"
  name               = var.app_name
  security_groups    = [aws_security_group.http.id]
  subnets            = module.network.public_subnet_ids
}
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "ok"
    }
  }
}
resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.main.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
resource "aws_lb_target_group" "main" {
  name   = var.app_name
  vpc_id = module.network.vpc_id
  port   = 80
  # 300sで登録解除は長いので60sに設定
  deregistration_delay = 60
  target_type          = "ip"
  protocol             = "HTTP"
  health_check {
    port = 80
    path = "/"
  }
}
