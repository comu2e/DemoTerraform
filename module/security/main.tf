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
resource "aws_security_group_rule" "worker_ingress" {
  security_group_id = aws_security_group.http.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
}
#================================ 
# ECSのエンドポイント設定
# https://zenn.dev/samuraikun/articles/0d22699a9878cd
# https://zenn.dev/yoshinori_satoh/articles/ecs-fargate-vpc-endpoint
# SGにaws vpc Endpoint interfaceを付与する。
# 新たにECSにendpointを設定したい場合はaws_vpc_endpointを設定する。
# HTTPS Port443のみ許可
# ECS Fargate Private SubnetでのEndPointを作成
# NAT gatewayを使わずにVPC Endpointを作成
# PrivateSubnetのRouteTable,vpc_endpointの設定
# Fargate v1.4ではecr.apiなど各種private link を設定する必要ある
# private_dns_enabled = trueで、プライベートDNSを有効化する必要ある
resource "aws_vpc_endpoint" "s3" {

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
}
resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count           = length(var.private_subnet)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = var.private_route_table[count.index].route_table_id
}

resource "aws_security_group" "ecs_endpoint" {
  name   = "${var.app_name}-vpc_endpoint_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = {
    "Name" = "ECS Endpoint"
  }
}
resource "aws_security_group_rule" "ecs_endpoint" {

  security_group_id = aws_security_group.ecs_endpoint.id

  type = "ingress"

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
# Interface型なので各種セキュリティグループと紐づく
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet
  security_group_ids  = [aws_security_group.ecs_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "private-ECR_DKR"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet
  security_group_ids  = [aws_security_group.ecs_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "private-ECR_API"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet
  security_group_ids  = [aws_security_group.ecs_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "private-logs"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet
  security_group_ids  = [aws_security_group.ecs_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "private-ssm"
  }
}

# SSH

resource "aws_security_group" "ssh" {
  vpc_id = var.vpc_id

  name        = "${var.app_name}-ssh"
  description = "${var.app_name}-ssh"
  tags = {
    Name = "${var.app_name}-ssh"
  }
}

# SecurityGroupRule
resource "aws_security_group_rule" "ingress_ssh" {
  security_group_id = aws_security_group.ssh.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
}
resource "aws_security_group_rule" "egress_ssh" {
  security_group_id = aws_security_group.ssh.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
}

# Redis-security group
resource "aws_security_group" "redis" {
  name        = "${var.app_name}-redis"
  description = "${var.app_name}-redis"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-redis"
  }
}

resource "aws_security_group_rule" "redis" {
  security_group_id = aws_security_group.redis.id

  type = "ingress"

  from_port   = 6379
  to_port     = 6379
  protocol    = "tcp"
  cidr_blocks = ["10.10.0.0/16"]
  # cidr_blocks = var.private_subnet_cidrs
}
#RDB
resource "aws_security_group" "db" {
  name        = "${var.app_name}-db"
  description = "${var.app_name}-db"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
  Name = "${var.app_name}-db" }
}

resource "aws_security_group_rule" "pgsql" {
  security_group_id = aws_security_group.db.id

  type = "ingress"

  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["10.10.0.0/16"]
  # cidr_blocks = var.private_subnet_cidrs
}
