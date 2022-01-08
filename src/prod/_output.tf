output "aws_vpc" {
  value = module.network.vpc_id
}

output "alb_dns_name" {
  value = module.alb.dns_name
}

# output "db_step_ip" {
#   value = module.compute.db_step_eip
# }
# output "db_endpoint" {
#   value = module.rds.endpoint
# }
output "db_subnets" {
  value = module.network.private_subnet_ids
}

output "ecs_exec_role" {
  value = module.iam.aws_iam_role_task_exection_arn
}

# output "redis_hostname" {
#   value = module.redis.redis_hostname
# }

output "db_security_groups" {
  value = module.sg.db_sg_id
}
# GitHub OIDCで使用

output "github_arn" {
  value = module.iam.github_role.arn
}
