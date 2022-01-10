
output "redis_hostname" {
  value = aws_elasticache_cluster.main.cache_nodes
}
