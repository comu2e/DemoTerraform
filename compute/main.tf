
variable "app_name" {
  type = string
}
variable "public_subnet_id" {
  type = string
}
variable "vpc_id" {
  type = string
}
# EC2
resource "aws_instance" "db" {
  ami           = "ami-0f27d081df46f326c"
  instance_type = "t3.nano"
  key_name      = aws_key_pair.main.id

  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = var.public_subnet_id

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

# SSHKey
# ご自身でデモする場合はssh-keygenでrsaキーを作成してpublic keyに設定してください
resource "aws_key_pair" "main" {
  key_name   = "sample-ec2-key"
  public_key = file("./compute/ec2/ec2.pub")
}
# EIP
resource "aws_eip" "db" {
  instance = aws_instance.db.id
  vpc      = true
  tags = {
    Name = "${var.app_name}-DB"
  }
}
resource "aws_security_group" "ec2" {
  vpc_id = var.vpc_id

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
  security_group_id = aws_security_group.ec2.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
}
