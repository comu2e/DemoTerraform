resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = var.app_name
  description = "${var.app_name}-internal"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "internal" {
  name = var.app_name
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}
