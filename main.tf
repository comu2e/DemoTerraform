provider "aws" {
  region = "ap-northeast-1"
  # version = "3.0"
}
terraform {
  required_version = "1.0.8"
}
module "network" {
  source               = "./network"
  app_name             = var.app_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}
module "ecs_endpoint" {
  depends_on          = [module.alb.aws_lb_target_group]
  source              = "./endpoint"
  app_name            = var.app_name
  vpc_cidr            = var.vpc_cidr
  vpc_id              = module.network.vpc_id
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

#ECS
resource "aws_ecs_cluster" "main" {
  name = var.app_name
}

module "ecs_app" {
  source                         = "./ecs"
  app_name                       = var.app_name
  placement_subnet               = module.network.private_subnet_ids
  target_group_arn               = module.alb.aws_lb_target_group
  aws_iam_role_task_exection_arn = module.iam.aws_iam_role_task_exection_arn
  cluster                        = aws_ecs_cluster.main.name
  sg                             = [aws_security_group.http.id, module.ecs_endpoint.endpoint_sg_id]
}
# SecurityGroup
module "alb" {
  source            = "./elb"
  app_name          = var.app_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  http_sg           = aws_security_group.http.id
}

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
