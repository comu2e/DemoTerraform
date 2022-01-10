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
  tags = {
    "Name" = "${var.app_name}-s3-endpoint"
  }
}
resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count           = length(var.private_subnets)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = var.private_route_tables[count.index].route_table_id
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
    "Name" = "${var.app_name}-ecsEndpoint"
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
  subnet_ids          = var.private_subnets
  security_group_ids  = [aws_security_group.ecs_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "${var.app_name}-private-ECR_DKR"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnets
  security_group_ids  = [aws_security_group.ecs_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "${var.app_name}-private-ECR_API"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnets
  security_group_ids  = [aws_security_group.ecs_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "${var.app_name}-private-logs"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnets
  security_group_ids  = [aws_security_group.ecs_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "${var.app_name}-private-ssm"
  }
}
resource "aws_vpc_endpoint" "ses" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.qldb.session"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnets
  security_group_ids  = [aws_security_group.ecs_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "${var.app_name}-private-ses"
  }
}
