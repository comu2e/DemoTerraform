
resource "aws_db_subnet_group" "main" {
  name        = lower(local.db_name)
  description = local.db_name
  subnet_ids  = var.private_subnet_ids
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier              = lower(var.app_name)
  engine                          = "aurora-postgresql"
  engine_version                  = "11.7"
  engine_mode                     = "provisioned"
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [var.db_sg_id]
  skip_final_snapshot             = true
  database_name                   = local.db_name
  master_username                 = local.db_username
  master_password                 = local.db_password
  backup_retention_period         = 5
  enabled_cloudwatch_logs_exports = ["postgresql"]
  preferred_backup_window         = "07:00-09:00"
  tags = {
    Name = var.app_name
  }
}
resource "aws_rds_cluster_instance" "postgresql" {
  count              = 2
  identifier         = "${var.app_name}-${count.index}"
  cluster_identifier = aws_rds_cluster.postgresql.cluster_identifier
  instance_class     = "db.r5.large"
  engine             = "aurora-postgresql"
  engine_version     = "11.7"

  # netowrok
  #availability_zone = ""   # eu-west-1a,eu-west-1b,eu-west-1c

  # monitoring
  performance_insights_enabled = false # default false
  monitoring_interval          = 60    # 0, 1, 5, 10, 15, 30, 60 (seconds). default 0 (off)
  monitoring_role_arn          = aws_iam_role.postgresql.arn

  # maintenance window
  preferred_maintenance_window = "Mon:03:00-Mon:04:00"

  # options
  db_parameter_group_name    = aws_db_parameter_group.postgresql.name
  auto_minor_version_upgrade = false

  # tags
  tags = {
    Service = "sample"
  }
}
# aws_db_parameter_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group
resource "aws_db_parameter_group" "postgresql" {
  name   = "sample-aurora-postgre-pg"
  family = "aurora-postgresql11"
  tags = {
    Service = "sample"
  }
}
# aws_iam_role
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "postgresql" {
  name               = "sample-rds-monitoring-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "monitoring.rds.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = {
    Name    = "sample-rds-monitoring-role"
    Service = "sample"
  }
}

# aws_iam_policy_attachment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment
resource "aws_iam_policy_attachment" "rds_monitoring_policy_attachment" {
  name       = "rds_monitoring_policy_attachment"
  roles      = [aws_iam_role.postgresql.name] # list
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
