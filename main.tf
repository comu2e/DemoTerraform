provider "aws" {
  region = "ap-northeast-1"
  # version = "~> 3.0"
}
terraform {
  required_version = "~> 1.0.8"
}
variable "app_name" {
  type    = string
  default = "FargateDemo"
}
variable "azs" {
  type    = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c"]
}
variable "vpc_cidr" {
  default = "10.10.0.0/16"
}

# PublicSubnets
variable "public_subnet_cidrs" {
  default = ["10.10.0.0/24", "10.10.1.0/24"]
}

# PrivateSubnets
variable "private_subnet_cidrs" {
  default = ["10.10.10.0/24", "10.10.11.0/24"]
}
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  # インスタンスがホスト上で共有されるようになります
  instance_tenancy = "default"
  tags = {
    "Name" = "${var.app_name}"
  }
}
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    "Name" = "${var.app_name}-Public-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    "Name" = "${var.app_name}-Private-${count.index}"
  }
}


# IGW
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.app_name
  }
}

# RouteTable(Public)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-public"
  }
}

# Route(Public)
resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
}

# RouteTableAssociation(Public)
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
# RouteTable Private

resource "aws_route_table" "private" {
  count  = length(aws_nat_gateway.ecs)
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.app_name}-private-${count.index}"
  }
}
# Route table private private内でのFaragateにDockerPullできるように設定
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route" "private" {
  count                  = length(aws_nat_gateway.ecs)
  route_table_id         = aws_route_table.private[count.index].id
  nat_gateway_id         = aws_nat_gateway.ecs[count.index].id
  destination_cidr_block = "0.0.0.0/0"
}


# EC2
resource "aws_instance" "db" {
  ami           = "ami-0f27d081df46f326c"
  instance_type = "t3.nano"
  key_name      = aws_key_pair.main.id

  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = aws_subnet.public[0].id

  # EBS最適化
  ebs_optimized = true

  # EBS
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    iops        = 3000
    # throughput            = 125
    delete_on_termination = true
  }
  tags = {
    "Name" = "${var.app_name}-DBStepInstance"
  }
}

# SecurityGroup
resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  name        = "${var.app_name}-ec2"
  description = "${var.app_name}-ec2"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-ec2"
  }
}

# SecurityGroupRule
resource "aws_security_group_rule" "ssh" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
}

resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
}

# SSHKey
# ご自身でデモする場合はssh-keygenでrsaキーを作成してpublic keyに設定してください
resource "aws_key_pair" "main" {
  key_name   = "sample-ec2-key"
  public_key = file("./ec2/ec2.pub")
}
# EIP
resource "aws_eip" "db" {
  instance = aws_instance.db.id
  vpc      = true

  tags = {
    Name = "${var.app_name}-DB"
  }
}
# Fargate用のNAT gateway用EIP
resource "aws_eip" "natgateway" {
  vpc   = true
  count = length(aws_subnet.public)

  tags = {
    Name = "${var.app_name}-Fargate"
  }
}
#ECS
####
#Cluster
####
resource "aws_ecs_cluster" "main" {
  name = var.app_name
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}
data "template_file" "container_definitions" {
  template = file("./container_definitions.json")
  # templateのjsonファイルに値を渡す
  vars = {
    tag        = "latest"
    name       = var.app_name
    account_id = local.account_id
    region     = local.region
  }
}
resource "aws_lb" "main" {
  load_balancer_type = "application"
  name               = var.app_name
  security_groups    = [aws_security_group.main.id]
  subnets            = aws_subnet.public.*.id
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
  vpc_id = aws_vpc.main.id
  port   = 80
  #コンテナのエフェメラルIPにバランシングするため
  target_type = "ip"
  protocol    = "HTTP"
  health_check {
    port = 80
    path = "/"
  }
}
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

resource "aws_iam_role" "task_execution" {
  name               = "${var.app_name}-TaskExecution"
  assume_role_policy = file("./task_execution_role.json")
}

resource "aws_iam_role_policy" "task_execution" {
  role   = aws_iam_role.task_execution.id
  policy = file("./task_execution_role_policy.json")

}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



resource "aws_ecs_task_definition" "main" {
  family = var.app_name

  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = data.template_file.container_definitions.rendered

  volume {
    name = "app-storage"
  }

  task_role_arn      = aws_iam_role.task_execution.arn
  execution_role_arn = aws_iam_role.task_execution.arn
}

resource "aws_ecs_service" "main" {
  depends_on = [aws_lb_listener_rule.main]

  name = var.app_name

  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  desired_count = 1

  cluster = aws_ecs_cluster.main.name

  task_definition = aws_ecs_task_definition.main.arn

  # GitHubActionsと整合性を取りたい場合は下記のようにrevisionを指定しなければよい
  # task_definition = "arn:aws:ecs:ap-northeast-1:${local.account_id}:task-definition/${aws_ecs_task_definition.main.family}"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "nginx"
    container_port   = 80
  }
}
# 
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 


# ECS用のSG、
#HTTP Port80のものを許可する
# SG
resource "aws_security_group" "ecs" {
  name        = "${var.app_name}-ecs"
  description = "${var.app_name}-ecs"

  vpc_id = aws_vpc.main.id

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

# SGR
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
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
}
resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count           = length(aws_route_table.private)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.private[count.index].id
}


resource "aws_security_group" "vpc_endpoint" {
  name   = "${var.app_name}-vpc_endpoint_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  tags = {
    "Name" = "ECS Endpoint"
  }
}

# Interface型なので各種セキュリティグループと紐づく
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "private-ECR_DKR"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "private-ECR_API"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "private-logs"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  tags = {
    "Name" = "private-ssm"
  }
}


resource "aws_nat_gateway" "ecs" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.natgateway[count.index].id
  # Publicに配置するのでsubnet_idはpublicとする。
  subnet_id = aws_subnet.public[count.index].id
  tags = {
    Name = "${var.app_name}-Fargate-NAT gw"
  }
  depends_on = [aws_internet_gateway.main]

}
