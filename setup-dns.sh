#!/bin/bash

# This is "DNS" Installation script

echo 'nameserver 8.8.8.8' | sudo tee --append /etc/resolv.conf

# Install packages

sudo yum install -y yum-utils bind bind-utils rpcbind nfs-server nfs-lock nfs-idmap git wget
sudo yum -y install wget git net-tools bind-utils iptables-services bridge-utils pythonvirtualenv gcc bash-completion

sudo systemctl enable named
sudo systemctl start named

# Download (clone) openshift-aws from github

mkdir -p /home/ec2-user/aws-in-openshift
git clone https://github.com/prasenforu/openshift-aws.git /home/ec2-user/aws-in-openshift/

# Setting and configuring DNS 

sudo cp /home/ec2-user/aws-in-openshift/cloudapps.cloud-cafe.in.db /var/named/dynamic/cloudapps.cloud-cafe.in.db
sudo cp /home/ec2-user/aws-in-openshift/cloud-cafe.in.db /var/named/dynamic/cloud-cafe.in.db
sudo rm /etc/named.conf
sudo cp /home/ec2-user/aws-in-openshift/named.conf /etc/named.conf

sudo chgrp named -R /var/named
sudo chown named -R /var/named/dynamic
sudo restorecon -R /var/named
sudo chown root:named /etc/named.conf
sudo restorecon /etc/named.conf
sudo systemctl status named
sudo systemctl restart named
sudo systemctl status named

# Setting Network for hostname change

echo 'preserve_hostname: true' | sudo tee --append /etc/cloud/cloud.cfg
sudo rm /etc/hostname
sudo touch /etc/hostname
echo 'ns1.cloud-cafe.in' | sudo tee --append /etc/hostname
echo 'HOSTNAME=ns1.cloud-cafe.in' | sudo tee --append /etc/sysconfig/network

# Setting passwordless login

echo 'StrictHostKeyChecking no' | sudo tee --append /etc/ssh/ssh_config
sudo ssh-keygen -f /root/.ssh/id_rsa -N ''

# Setting up yum repo for openshift

sudo cp /home/ec2-user/aws-in-openshift/open.repo /etc/yum.repos.d/open.repo
sudo yum clean all
sudo yum repolist
sudo yum -y update

# Install Docker and Docker-compose

sudo yum -y install docker
sudo systemctl enable docker
sudo systemctl start docker

sudo curl -L "https://github.com/docker/compose/releases/download/1.9.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo cat /home/ec2-user/aws-in-openshift/hostfile >> /etc/hosts

# Setting UP passwordless login from DNS server

for node in {ose-master,ose-hub,ose-node1}; do
echo "Deploy SSH Key on $node" && \
scp -i prasen.pem /root/.ssh/id_rsa.pub ec2-user@$node:/home/ec2-user/.ssh/id_rsa.pub_root
ssh ec2-user@$node -i prasen.pem "sudo mv /home/ec2-user/.ssh/id_rsa.pub_root /root/.ssh/authorized_keys"
ssh ec2-user@$node -i prasen.pem "sudo chown root:root /root/.ssh/authorized_keys"
ssh ec2-user@$node -i prasen.pem "sudo chmod 600 /root/.ssh/authorized_keys"
ssh ec2-user@$node -i prasen.pem "sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config"
ssh ec2-user@$node -i prasen.pem "sudo sed -i \"s/$PasswordAuthentication no/$PasswordAuthentication yes/g\" /etc/ssh/sshd_config"
ssh ec2-user@$node -i prasen.pem "sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config"
ssh ec2-user@$node -i prasen.pem "sudo service sshd restart"
done

# Rebooting servers

for node in {ose-master,ose-hub,ose-node1}; do
echo "Rebooting $node" && \
ssh $node reboot
done

# Run it from DNS server

for node in {ose-master,ose-hub,ose-node1}; do
echo "Deploy Openshift Repo on $node" && \
scp /etc/yum.repos.d/open.repo $node:/etc/yum.repos.d/open.repo
scp /etc/resolv.conf $node:/etc/resolv.conf
yum clean all
yum repolist
done

# Install Openshift 3.3

# 1. First Install "bash-completion" & the following tools and utilities on the master host

ssh ose-master "yum -y install wget git net-tools bind-utils iptables-services bridge-utils pythonvirtualenv gcc bash-completion"

# 2. Run yum update on the master and all the nodes:

for node in {ose-master,ose-hub,ose-node1}; do
echo "Running yum update on $node" && \
ssh $node "yum -y update"
ssh $node "yum install -y wget git net-tools bind-utils"
done

# 3. Install docker in all hosts.

for node in {ose-master,ose-hub,ose-node1}; do
echo "Installing Docker on $node" && \
ssh $node "sudo yum -y install docker"
ssh $node "chcon -t docker_exec_t /usr/bin/docker*"
ssh $node "chcon -Rt svirt_sandbox_file_t /var/lib"
ssh $node "chcon -Rt svirt_sandbox_file_t /var/db"
ssh $node "systemctl enable docker"
ssh $node "systemctl start docker"
done 

# 4. Starting OSE installation

yum -y install atomic-openshift-utils

ansible-playbook -i myconfighost /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
