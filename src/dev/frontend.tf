# variable
locals {
  app_name = "${var.app_name}-admin-hm"
}

# ==========================================================
# ELB の設定
# ==========================================================
module "front_elb" {
  source            = "../_module/elb"
  app_name          = local.app_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  http_sg           = module.frontend_sg.frotend__alb_sg_id
  port              = 80
}

# ==========================================================
# IAM 設定
# ==========================================================
# module "front_iam" {
#   source   = "../_module/iam"
#   app_name = local.app_name

#   # github action で使用
#   system      = var.app_name
#   github_repo = "sumarch/housebokan-admin-hm"
# }

# ==========================================================
# フロント用のSG
# ==========================================================
module "frontend_sg" {
  source              = "../_module/security/frontend"
  app_name            = local.app_name
  vpc_cidr            = var.vpc_cidr
  vpc_id              = module.network.vpc_id
  private_route_table = module.network.route_table_private
  private_subnets     = module.network.private_subnet_ids
}

# ========================================================
# ECS 作成
# ========================================================
module "front_ecs" {
  source             = "../_module/ecs/frontend"
  app_name           = local.app_name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  cluster_name = aws_ecs_cluster.main.name
  # elb の設定
  target_group_arn = module.front_elb.aws_lb_target_group
  # ECS のtask に関連付けるIAM の設定
  iam_role_task_execution_arn = module.iam.aws_iam_role_task_exection_arn
  port                        = 3000 # task定義に渡すport

  sg_list = [
    module.frontend_sg.frotend__alb_sg_id # ALBの設定
  ]
}
