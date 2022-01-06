output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "route_table_public" {
  value = aws_route.public
}
output "route_table_private" {
  value = aws_route.private[*]
}
