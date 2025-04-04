#!/bin/bash

sudo yum update -y
sudo yum install -y docker wget amazon-efs-utils

sudo service docker start
sudo systemctl enable docker.service
sudo usermod -aG docker ec2-user

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo mkdir -p /wordpress
sudo mount -t efs -o tls #seu mount efs:/ /wordpress <- pasta do projeto

if mountpoint -q /wordpress; then
    echo "EFS montado com sucesso em /wordpress"
else
    echo "Falha ao montar EFS"
fi

wget -O /home/ec2-user/docker-compose.yml https://raw.githubusercontent.com/hidalgobru/script/refs/heads/main/docker-compose.yml
sudo chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml

cd /home/ec2-user
sudo docker-compose up -d