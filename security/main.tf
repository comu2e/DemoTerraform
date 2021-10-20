variable "vpc_id" {
  description = "HTTPアクセス用のセキュリティグループ"
  type        = string
}
variable "app_name" {
  type = string
}

resource "aws_security_group" "http" {
  vpc_id = var.vpc_id

  name        = "${var.app_name}-main"
  description = "${var.app_name}-main"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.app_name}-main"
  }
}

resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.http.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
}

output "http_access_sg" {
  value = aws_security_group_rule.http
}
