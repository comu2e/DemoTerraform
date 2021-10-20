variable "app_name" {
  description = "Application Name"
  type        = string
}
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "http_sg" {
  description = "HTTP access security group"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet ids."
  type        = list(string)
}

resource "aws_lb" "main" {
  load_balancer_type = "application"
  name               = var.app_name
  security_groups    = [var.http_sg]
  #   security_groups    = [aws_security_group.http.id]
  subnets = var.public_subnet_ids
  #   subnets            = module.network.public_subnet_ids
}
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "ok"
    }
  }
}
resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.main.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
resource "aws_lb_target_group" "main" {
  name   = var.app_name
  vpc_id = var.vpc_id
  port   = 80
  # 300sで登録解除は長いので60sに設定
  deregistration_delay = 60
  target_type          = "ip"
  protocol             = "HTTP"
  health_check {
    port = 80
    path = "/"
  }
}

output "aws_lb_target_group" {
  value = aws_lb_target_group.main.arn
}
output "dns_name" {
  value = aws_lb.main.dns_name
}
