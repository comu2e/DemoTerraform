output "aws_vpc" {
  value = module.network.vpc_id
}

output "alb_dns_name" {
  value = module.alb.dns_name
}

output "db_step_ip" {
  value = module.compute.db_step_eip
}
output "db_endpoint" {
  value = module.rds.endpoint
}
output "ecs_exec_role"{
  value = module.iam.aws_iam_role_task_exection_arn
}