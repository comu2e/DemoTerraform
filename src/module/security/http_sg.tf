resource "aws_security_group" "http" {

  name        = "${var.app_name}-main"
  description = "${var.app_name}-main"
  vpc_id      = var.vpc_id
  tags = {
    Name = "${var.app_name}-main"
  }
}
resource "aws_security_group_rule" "http_egress" {
  security_group_id = aws_security_group.http.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "all"
}
resource "aws_security_group_rule" "https_egress" {
  security_group_id = aws_security_group.http.id
  type              = "egress"
  # ここをcidr_blocks = var.cidr_blocks
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
}
resource "aws_security_group_rule" "http_ingress" {
  security_group_id = aws_security_group.http.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
}
resource "aws_security_group_rule" "https_ingress" {
  security_group_id = aws_security_group.http.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
}