
variable "app_name" {
  type = string
}
variable "public_subnet_id" {
  type = string
}

variable "public_sg" {
  type = list(string)
}
# EC2
resource "aws_instance" "db" {
  ami           = "ami-0f27d081df46f326c"
  instance_type = "t3.nano"
  key_name      = aws_key_pair.main.id

  vpc_security_group_ids = var.public_sg
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
