variable "app_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
# 事前にSSMでパラメータを設定しておく
data "aws_ssm_parameter" "db_username" {
  name = "DB_USERNAME"
}
data "aws_ssm_parameter" "db_name" {
  name = "DB_NAME"
}
data "aws_ssm_parameter" "db_password" {
  name = "DB_PASSWORD"
}
locals {

  db_username = data.aws_ssm_parameter.db_username.value
  db_password = data.aws_ssm_parameter.db_password.value
  db_name     = data.aws_ssm_parameter.db_name.value
}

resource "aws_db_instance" "this" {
  allocated_storage         = 10
  max_allocated_storage     = 30
  final_snapshot_identifier = var.app_name

  vpc_security_group_ids = [aws_security_group.this.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  engine              = "postgres"
  engine_version      = "12.5"
  instance_class      = "db.t3.micro"
  name                = lower(local.db_name)
  username            = local.db_username
  password            = local.db_password
  port                = 5432
  skip_final_snapshot = true
}
resource "aws_security_group" "this" {
  name        = local.db_name
  description = local.db_name

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.db_name
  }
}

resource "aws_security_group_rule" "pgsql" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["10.5.0.0/16"]

}

resource "aws_db_subnet_group" "this" {
  name        = "db-subnet"
  description = local.db_name
  subnet_ids  = var.private_subnet_ids
}

output "endpoint" {
  value = aws_db_instance.this.endpoint
}
