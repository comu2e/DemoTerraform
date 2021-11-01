output "http_sg_id" {
  value = aws_security_group.http.id
}

output "endpoint_sg_id" {
  value = aws_security_group.ecs_endpoint.id
}

output "ssh_sg_id" {
  value = aws_security_group.ssh.id
}

output "redis_sg_id" {
  value = aws_security_group.redis.id
}

output "db_sg_id" {
  value = aws_security_group.db.id
}
