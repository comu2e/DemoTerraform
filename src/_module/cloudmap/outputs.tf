output "cloudmap_internal_Arn" {
  description = "use for ecs service definition"
  value       = aws_service_discovery_service.internal.arn
}
