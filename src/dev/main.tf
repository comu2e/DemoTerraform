provider "aws" {
  region = "ap-northeast-1"
  # version = "3.0"
}
terraform {
<<<<<<< HEAD
  required_version = "1.1.4"
=======
  required_version = "1.1.3"
>>>>>>> 36c351ea505eae2cb263864b70847284675b8684
}
module "network" {
  source               = "../_module/network"
  azs                  = var.azs
  app_name             = var.app_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
# SecurityGroup
module "sg" {
  source                = "../_module/security_group"
  app_name              = var.app_name
  vpc_cidr              = var.vpc_cidr
  vpc_id                = module.network.vpc_id
  private_route_tables  = module.network.route_table_private
  private_subnets       = module.network.private_subnet_ids
  private_subnets_cidrs = var.private_subnet_cidrs

}

# IAM role
module "iam" {
  source      = "../_module/iam"
  app_name    = var.app_name
  system      = var.app_name
  github_repo = "comu2e/test-worker-scheduler"
}
module "compute" {
  source           = "../_module/compute"
  app_name         = var.app_name
  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_ids[0]
  ssh_sg_id        = module.sg.ssh_sg_id
}
#ECS
module "alb" {
  source            = "../_module/elb"
  app_name          = var.app_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  http_sg           = module.sg.http_sg_id
  port              = 80
}

resource "aws_ecs_cluster" "main" {
  name = var.app_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# module "ecs_app" {
#   source                         = "../_module/ecs/backend/app"
#   task_definition_file_path      = "../_module/ecs/backend/app/container_definitions.json"
#   entry_container_name           = "nginx"
#   entry_container_port           = 80
#   app_name                       = var.app_name
#   cluster                        = aws_ecs_cluster.main.name
#   placement_subnet               = module.network.private_subnet_ids
#   target_group_arn               = module.alb.aws_lb_target_group
#   aws_iam_role_task_exection_arn = module.iam.aws_iam_role_task_exection_arn
#   sg_list                        = [module.sg.http_sg_id, module.sg.endpoint_sg_id, module.sg.redis_ecs_sg_id]
# }

# module "ecs_worker" {
#   source = "../_module/ecs/backend/worker"
#   # task_definition_file_path      = "../_module/ecs/worker/container_definitions.json"
#   entry_container_name = "worker"
#   entry_container_port = 6379
#   app_name             = var.app_name
#   cluster              = aws_ecs_cluster.main.name
#   placement_subnet     = module.network.private_subnet_ids
#   # target_group_arn               = module.alb.aws_lb_target_group
#   aws_iam_role_task_exection_arn = module.iam.aws_iam_role_task_exection_arn
#   sg = [
#     module.sg.http_sg_id,
#     module.sg.endpoint_sg_id,
#     module.sg.redis_ecs_sg_id,
#     module.sg.ses_ecs_sg_id
#   ]

#   vpc_id      = module.network.vpc_id
#   cluster_arn = aws_ecs_cluster.main.arn
# }


# module "redis" {
#   source             = "../_module/redis"
#   app_name           = var.app_name
#   vpc_id             = module.network.vpc_id
#   redis_sg_id        = module.sg.redis_ecs_sg_id
#   private_subnet_ids = module.network.private_subnet_ids
# }

# module "rds" {
#   source             = "../_module/db"
#   app_name           = var.app_name
#   vpc_id             = module.network.vpc_id
#   db_sg_id           = module.sg.db_sg_id
#   instace_type       = "db.t3.medium"
#   private_subnet_ids = module.network.private_subnet_ids
# }

