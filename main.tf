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

# EC2
resource "aws_instance" "main" {
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
resource "aws_eip" "main" {
  instance = aws_instance.main.id
  vpc      = true

  tags = {
    Name = var.app_name
  }
}

#ECS
####
#Cluster
####
resource "aws_ecs_cluster" "main" {
  name = var.app_name
}

data "template_file" "container_definitions" {
  template = file("./container_definitions.json")
  # templateのjsonファイルに値を渡す
  vars = {
    tag  = "latest"
    name = var.app_name

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
