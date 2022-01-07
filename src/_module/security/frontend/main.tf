# =====================================================
# frontの　ALB に付与

# user からのアクセスを受け付けてコンテナに流す
# =====================================================
resource "aws_security_group" "frontend" {
  name        = "${var.app_name}-alb-frontend"
  description = "${var.app_name}-alb-frontend"
  vpc_id      = var.vpc_id

  # セキュリティグループ内のリソースからインターネットへのアクセスを許可する
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-alb-frontend"
  }
}

# user から80, 443 でくる通信を受け取る
resource "aws_security_group_rule" "http_frontend_80" {
  security_group_id = aws_security_group.frontend.id

  # セキュリティグループ内のリソースへインターネットからのアクセスを許可する
  type = "ingress"

  from_port = 80
  to_port   = 80
  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}
# user から80, 443 でくる通信を受け取る
resource "aws_security_group_rule" "http_frontend_3000" {
  security_group_id = aws_security_group.frontend.id

  # セキュリティグループ内のリソースへインターネットからのアクセスを許可する
  type = "ingress"

  from_port = 3000
  to_port   = 3000
  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}
# ALB用セキュリティグループへhttpsも受け付けるようルールを追加する
resource "aws_security_group_rule" "https_frontend_443" {
  security_group_id = aws_security_group.frontend.id

  type = "ingress"

  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}

# ALB -> コンテナへ3000 になるようにおまじない
resource "aws_security_group_rule" "https_frontend_egress_3000" {
  security_group_id = aws_security_group.frontend.id

  type = "egress"

  from_port = 3000
  to_port   = 3000
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}