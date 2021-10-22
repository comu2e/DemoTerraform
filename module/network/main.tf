
variable "app_name" {
  description = "Application Name"
  type        = string
}
variable "vpc_cidr" {
  description = "VPC CIDR blocks"
  type        = string
}
variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR blocks"
  type        = list(string)
}
variable "private_subnet_cidrs" {
  description = "Public Subnet CIDR blocks"
  type        = list(string)
}
variable "azs" {
  description = "Availability zones"
  type        = list(string)
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
  # instanceにパブリックIPを自動的に割り当てる
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.app_name}-Public-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  # instanceにパブリックIPは不要
  map_public_ip_on_launch = false
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
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
# RouteTable Private

resource "aws_nat_gateway" "ecs" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.natgateway[count.index].id
  # Publicに配置するのでsubnet_idはpublicとする。
  subnet_id = aws_subnet.public[count.index].id
  tags = {
    Name = "${var.app_name}-Fargate-NAT gw"
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
resource "aws_route_table" "private" {
  count  = length(aws_subnet.public)
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
  count                  = length(aws_subnet.private)
  route_table_id         = aws_route_table.private[count.index].id
  nat_gateway_id         = aws_nat_gateway.ecs[count.index].id
  destination_cidr_block = "0.0.0.0/0"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "route_table_public" {
  value = aws_route.public
}
output "route_table_private" {
  value = aws_route.private[*]
}
