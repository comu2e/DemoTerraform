resource "aws_elasticache_subnet_group" "main" {
  name        = local.name
  description = local.name
  subnet_ids  = var.private_subnet_ids
}

resource "aws_elasticache_cluster" "main" {
  cluster_id         = var.app_name
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [var.redis_sg_id]

  engine               = "redis"
  engine_version       = "5.0.6"
  port                 = 6379
  parameter_group_name = "default.redis5.0"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  tags = {
    "Name" = "${var.app_name}-redis"
  }
}
