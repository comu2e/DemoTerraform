#RDB instacne securty group / DB Bastion Security group.
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
