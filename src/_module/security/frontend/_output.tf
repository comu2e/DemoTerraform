# Frontend の ALB / ECSでも使用
output "frotend__alb_sg_id" {
  value = aws_security_group.frontend.id
}