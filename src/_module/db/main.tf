
resource "aws_db_subnet_group" "main" {
  name        = lower(replace(var.app_name, "-", "_"))
  description = local.db_name
  subnet_ids  = var.private_subnet_ids
}

resource "aws_db_instance" "main" {
  identifier             = lower(var.app_name)
  vpc_security_group_ids = [var.db_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  allocated_storage = 10
  engine            = "postgres"
  engine_version    = "11.13"
  instance_class    = var.instace_type
  port              = 5432
  name              = local.db_name
  username          = local.db_username
  password          = local.db_password

  final_snapshot_identifier = var.app_name
  skip_final_snapshot       = true
}
