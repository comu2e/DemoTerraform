output "aws_vpc" {
  value = module.network.vpc_id
}

output "alb_dns_name" {
  value = module.alb.dns_name
}
