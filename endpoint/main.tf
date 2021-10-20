#================================ 
# ECSのエンドポイント設定
# SGにaws vpc Endpoint interfaceを付与する。
# 新たにECSにendpointを設定したい場合はaws_vpc_endpointを設定する。
# HTTPS Port443のみ許可


variable "vpc_id" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "app_name" {
  type = string
}
variable "private_route_table" {
  type = list(any)
}
variable "private_subnet" {
  type = list(string)
}

resource "aws_security_group" "ecs" {
  name        = "${var.app_name}-ecs"
  description = "${var.app_name}-ecs"

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-ecs"
  }
}


resource "aws_security_group_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id

  type = "ingress"

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# ECS Fargate Private SubnetでのEndPointを作成
# NAT gatewayを使わずにVPC Endpointを作成
# https://zenn.dev/samuraikun/articles/0d22699a9878cd
# https://zenn.dev/yoshinori_satoh/articles/ecs-fargate-vpc-endpoint
# PrivateSubnetのRouteTable,vpc_endpointの設定
# Fargate v1.4ではecr.apiなど各種private link を設定する必要ある
# private_dns_enabled = trueで、プライベートDNSを有効化する必要ある
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
}
resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count           = length(var.private_route_table)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = var.private_route_table[count.index].id
}


resource "aws_security_group" "vpc_endpoint" {
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

# Interface型なので各種セキュリティグループと紐づく
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
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
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
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
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
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
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "private-ssm"
  }
}


output "endpoint_sg_id" {
  value = aws_security_group.ecs.id
}
