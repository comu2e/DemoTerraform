resource "aws_security_group" "main" {
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
  security_group_id = aws_security_group.main.id

  type = "ingress"

  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["10.10.0.0/16"]
}

resource "aws_db_subnet_group" "main" {
  name        = lower(local.db_name)
  description = local.db_name
  subnet_ids  = var.private_subnet_ids
}

resource "aws_db_instance" "main" {
  identifier             = lower(var.app_name)
  vpc_security_group_ids = [aws_security_group.main.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  allocated_storage = 10
  engine            = "postgres"
  engine_version    = "12.5"
  instance_class    = "db.t3.micro"
  port              = 5432
  name              = local.db_name
  username          = local.db_username
  password          = local.db_password

  final_snapshot_identifier = var.app_name
  skip_final_snapshot       = true
}
