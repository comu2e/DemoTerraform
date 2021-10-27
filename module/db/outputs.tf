output "endpoint" {
  value = aws_db_instance.main.endpoint
}
output "db_private_subnet" {
  value = aws_db_instance.main.db_subnet_group_name
}
output "db_sg" {
  value = aws_security_group.main.id
}
