output "endpoint" {
  value = aws_rds_cluster.postgresql.endpoint
}
output "db_private_subnet" {
  value =aws_rds_cluster.postgresql.db_subnet_group_name
}
