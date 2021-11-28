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
