# Redis/Worker Security group.
resource "aws_security_group_rule" "worker_ingress" {
  security_group_id = aws_security_group.http.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
}

resource "aws_security_group" "redis_ecs" {
  name        = "${var.app_name}-redis_ecs"
  description = "${var.app_name}-redis_ecs"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
  }
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.app_name}-redis_ecs"
  }
}

