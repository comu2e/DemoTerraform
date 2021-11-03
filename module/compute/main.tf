
# EC2
resource "aws_instance" "db" {
  ami           = "ami-0f27d081df46f326c"
  instance_type = "t3.nano"
  key_name      = aws_key_pair.main.id

  vpc_security_group_ids = [var.ssh_sg_id]
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


  user_data = <<EOF
  #!/bin/bash
  yum update -y

  ### mysql
  yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
  yum install -y yum-utils
  yum-config-manager --disable mysql80-community
  yum-config-manager --enable mysql57-community
  yum install -y mysql-community-client
  
  ### psql
  rpm -ivh --nodeps https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  sed -i "s/\$releasever/7/g" "/etc/yum.repos.d/pgdg-redhat-all.repo"
  yum install -y postgresql12
  # Redis
  sudo amazon-linux-extras install redis6
  yum install -y redis --enablerepo=epel
  ### JST
  sed -ie 's/ZONE=\"UTC\"/ZONE=\"Asia\/Tokyo\"/g' /etc/sysconfig/clock
  sed -ie 's/UTC=true/UTC=false/g' /etc/sysconfig/clock
  ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

  ### locale
  sed -ie 's/en_US\.UTF-8/ja_JP\.UTF-8/g' /etc/sysconfig/i18n

  EOF

}

# SSHKey
# ご自身でデモする場合はssh-keygenでrsaキーを作成してpublic keyに設定してください
resource "aws_key_pair" "main" {
  key_name   = "ec2"
  public_key = file(abspath("./module/compute/ec2/ec2.pub"))
}
# EIP
resource "aws_eip" "db" {
  instance = aws_instance.db.id
  vpc      = true
  tags = {
    Name = "${var.app_name}-DB"
  }
}

