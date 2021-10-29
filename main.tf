provider "aws" {
  region = "ap-northeast-1"
  # version = "3.0"
}
terraform {
  required_version = "1.0.8"
}
module "network" {
  source               = "./module/network"
  azs                  = var.azs
  app_name             = var.app_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
# SecurityGroup
module "sg" {
  source              = "./module/security"
  app_name            = var.app_name
  vpc_cidr            = var.vpc_cidr
  vpc_id              = module.network.vpc_id
  private_route_table = module.network.route_table_private
  private_subnet      = module.network.private_subnet_ids
}

# IAM role
module "iam" {
  source   = "./module/iam"
  app_name = var.app_name
}
module "compute" {
  source           = "./module/compute"
  app_name         = var.app_name
  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_ids[0]
  ssh_sg_id        = module.sg.ssh_sg_id
}

module "rds" {
  source             = "./module/db"
  app_name           = var.app_name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
}
#ECS
module "alb" {
  source            = "./module/elb"
  app_name          = var.app_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  http_sg           = module.sg.http_sg_id
}

resource "aws_ecs_cluster" "main" {
  name = var.app_name
}

module "ecs_app" {
  source                         = "./module/ecs"
  task_definition_file_path      = "./module/ecs/container_definitions.json"
  entry_container_name           = "nginx"
  entry_container_port           = 80
  app_name                       = var.app_name
  cluster                        = aws_ecs_cluster.main.name
  placement_subnet               = module.network.private_subnet_ids
  target_group_arn               = module.alb.aws_lb_target_group
  aws_iam_role_task_exection_arn = module.iam.aws_iam_role_task_exection_arn
  sg                             = [module.sg.http_sg_id, module.sg.endpoint_sg_id]
  service_registries_arn         = module.cloudmap.cloudmap_internal_Arn
}

module "cloudmap" {
  source   = "./module/cloudmap"
  app_name = var.app_name
  vpc_id   = module.network.vpc_id
}

# module "ecs_worker" {
#   source                         = "./module/ecs"
#   task_definition_file_path      = "./module/ecs/worker_container_defitions.json"
#   entry_container_name           = "worker"
#   entry_container_port           = 6379
#   app_name                       = var.app_name
#   cluster                        = aws_ecs_cluster.main.name
#   placement_subnet               = module.network.private_subnet_ids
#   target_group_arn               = module.alb.aws_lb_target_group
#   aws_iam_role_task_exection_arn = module.iam.aws_iam_role_task_exection_arn
#   sg                             = [module.sg.http_sg_id, module.sg.endpoint_sg_id]
# }

module "redis" {
  source             = "./module/redis"
  app_name           = var.app_name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
}
