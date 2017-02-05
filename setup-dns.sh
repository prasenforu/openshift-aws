#!/bin/bash

# This is "DNS" Installation script

echo nameserver 8.8.8.8 >> /etc/resolv.conf

# Install packages

sudo yum install -y yum-utils bind bind-utils rpcbind nfs-server nfs-lock nfs-idmap git wget
sudo yum -y install wget git net-tools bind-utils iptables-services bridge-utils pythonvirtualenv gcc bash-completion

sudo systemctl enable named
sudo systemctl start named

# Download (clone) openshift-aws from github

mkdir -p /home/ec2-user/aws-in-openshift
git clone https://github.com/prasenforu/openshift-aws.git /home/ec2-user/aws-in-openshift/

# Setting and configuring DNS 

sudo cp /home/ec2-user/aws-in-openshift/openshift-aws/cloudapps.cloud-cafe.in.db /var/named/dynamic/cloudapps.cloud-cafe.in.db
sudo cp /home/ec2-user/aws-in-openshift/openshift-aws/cloud-cafe.in.db /var/named/dynamic/cloud-cafe.in.db
sudo rm /etc/named.conf
sudo cp /home/ec2-user/aws-in-openshift/openshift-aws/named.conf /etc/named.conf

sudo chgrp named -R /var/named
sudo chown named -R /var/named/dynamic
sudo restorecon -R /var/named
sudo chown root:named /etc/named.conf
sudo restorecon /etc/named.conf
sudo systemctl status named
sudo systemctl restart named
sudo systemctl status named

# Setting Network for hostname change

sudo echo preserve_hostname: true >>/etc/cloud/cloud.cfg
sudo echo ns1.cloud-cafe.in > /etc/hostname
sudo echo HOSTNAME=ns1.cloud-cafe.in >> /etc/sysconfig/network

# Setting passwordless login

sudo echo StrictHostKeyChecking no >> /etc/ssh/ssh_config
sudo ssh-keygen -f /root/.ssh/id_rsa -N ''

# Setting up yum repo for openshift

sudo cp /home/ec2-user/aws-in-openshift/openshift-aws/open.repo /etc/yum.repos.d/open.repo
sudo yum clean all
sudo yum repolist
sudo yum -y update

# Install Docker and Docker-compose

sudo yum -y install docker
sudo systemctl enable docker
sudo systemctl start docker

sudo curl -L "https://github.com/docker/compose/releases/download/1.9.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose