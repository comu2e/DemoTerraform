output "http_sg_id" {
  value = aws_security_group.http.id
}

output "endpoint_sg_id" {
  value = aws_security_group.ecs_endpoint.id
}

output "ssh_sg_id" {
  value = aws_security_group.ssh.id
}

output "db_sg_id" {
  value = aws_security_group.db.id
}

output "redis_ecs_sg_id" {
  value = aws_security_group.redis_ecs.id
}

output "ses_ecs_sg_id" {
  value = aws_security_group.ses_ecs.id
}
