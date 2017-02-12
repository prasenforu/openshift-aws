#!/bin/bash

# Variable

dom=cloud-cafe.in
acky=
sacky=
reg=ap-southeast-2
iid=ami-39ac915a
ity=t2.micro
knm=prasen
subprid=subnet-5861ed2e
subpuid=subnet-84f095e0
sgidm=sg-258d5642
sgidh=sg-3b59fe5c
sgidn=sg-7959fe1e 
volsz=10


# This is "DNS" Installation script

echo 'nameserver 8.8.8.8' | sudo tee --append /etc/resolv.conf

# Install packages

sudo yum install -y yum-utils bind bind-utils rpcbind nfs-server nfs-lock nfs-idmap git wget
sudo yum -y install wget git net-tools bind-utils iptables-services bridge-utils pythonvirtualenv gcc bash-completion

sudo systemctl enable named
sudo systemctl start named

# Download (clone) openshift-aws from github

mkdir -p /home/ec2-user/aws-in-openshift
git clone https://github.com/$knmforu/openshift-aws.git /home/ec2-user/aws-in-openshift/

# Setting and configuring DNS 

sudo cp /home/ec2-user/aws-in-openshift/cloudapps.$dom.db /var/named/dynamic/cloudapps.$dom.db
sudo cp /home/ec2-user/aws-in-openshift/$dom.db /var/named/dynamic/$dom.db
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
echo 'ns1.$dom' | sudo tee --append /etc/hostname
echo 'HOSTNAME=ns1.$dom' | sudo tee --append /etc/sysconfig/network

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

#####################  AWS CLI Script #############################

# This script will install AWS CLI tool

# Check AWS CLI installed or not
# If not installed it will start download and install

if ! type "aws" > /dev/null; then
    echo "Installing AWS ..."
    echo "Downloading AWS CLI package and unzip"
        wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
        unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
mkdir ~/.aws
touch ~/.aws/config

echo "Setting Access Key and Secret Access Key ..."

cp /home/ec2-user/aws-in-openshift/config ~/.aws/config
else
    echo "AWS CLI is already Installed."
    cp /home/ec2-user/aws-in-openshift/config ~/.aws/config
fi

###############  Launch Instance using AWS CLI #####################

# MASTER Server 

echo "Starting OSE MASTER Host .."

aws ec2 run-instances --image-id $iid --count 1 \
--instance-type $ity --key-name $knm --security-group-ids $sgidm \
--subnet-id $subpuid --private-ip-address 10.90.1.208 --associate-public-ip-address

# HUB/Router Server

echo "Starting OSE HUB/Router Host .."

aws ec2 run-instances --image-id $iid --count 1 \
--instance-type $ity --key-name $knm --security-group-ids $sgidh \
--subnet-id $subpuid --private-ip-address 10.90.1.209 --associate-public-ip-address

# NDOE1 Server

echo "Starting OSE NODE-1 Host .."

aws ec2 run-instances --image-id $iid --count 1 \
--instance-type $ity --key-name $knm --security-group-ids $sgidn \
--subnet-id $subprid --private-ip-address 10.90.2.210 

# NDOE2 Server

echo "Starting OSE NODE-2 Host .."

aws ec2 run-instances --image-id $iid --count 1 \
--instance-type $ity --key-name $knm --security-group-ids $sgidn \
--subnet-id $subprid --private-ip-address 10.90.2.211

###############  NExT Step 1 #####################

# Setting UP passwordless login from DNS server

echo "Setting Password less login for ALL servers .."

for node in {ose-master,ose-hub,ose-node1}; do
echo "Deploy SSH Key on $node" && \
scp -i $knm.pem /root/.ssh/id_rsa.pub ec2-user@$node:/home/ec2-user/.ssh/id_rsa.pub_root
ssh ec2-user@$node -i $knm.pem "sudo mv /home/ec2-user/.ssh/id_rsa.pub_root /root/.ssh/authorized_keys"
ssh ec2-user@$node -i $knm.pem "sudo chown root:root /root/.ssh/authorized_keys"
ssh ec2-user@$node -i $knm.pem "sudo chmod 600 /root/.ssh/authorized_keys"
ssh ec2-user@$node -i $knm.pem "sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config"
ssh ec2-user@$node -i $knm.pem "sudo sed -i \"s/$PasswordAuthentication no/$PasswordAuthentication yes/g\" /etc/ssh/sshd_config"
ssh ec2-user@$node -i $knm.pem "sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config"
ssh ec2-user@$node -i $knm.pem "sudo service sshd restart"
done

# Rebooting servers

for node in {ose-master,ose-hub,ose-node1}; do
echo "Rebooting $node" && \
ssh $node reboot
done

echo "Waiting for servers up ...."
sleep 200

# Configuring Repo and setting network

for node in {ose-master,ose-hub,ose-node1}; do
echo "Deploy Openshift Repo on $node" && \
scp /etc/yum.repos.d/open.repo $node:/etc/yum.repos.d/open.repo
ssh $node "echo 'nameserver 8.8.8.8' | sudo tee --append /etc/resolv.conf"
ssh $node "echo 'preserve_hostname: true' | sudo tee --append /etc/cloud/cloud.cfg"
ssh $node "rm /etc/hostname"
ssh $node "touch /etc/hostname"
ssh $node "echo '$node.$dom' | sudo tee --append /etc/hostname"
ssh $node "echo 'HOSTNAME=$node.$dom' | sudo tee --append /etc/sysconfig/network"
yum clean all
yum repolist
done

# Rebooting servers

for node in {ose-master,ose-hub,ose-node1}; do
echo "Rebooting $node" && \
ssh $node reboot
done

echo "Waiting for servers up ...."
sleep 200

###############  Docker Storage Setup #####################

# Install Openshift 3.3 packages

ssh ose-master "yum -y install wget git net-tools bind-utils iptables-services bridge-utils pythonvirtualenv gcc bash-completion"

# yum update on the master and all the nodes:

for node in {ose-master,ose-hub,ose-node1}; do
echo "Running yum update on $node" && \
ssh $node "yum -y update"
ssh $node "yum install -y wget git net-tools bind-utils"
done

# Install docker in all hosts.
# Below chcon only it you OSE 3.3 on RHEL 7.3
# OSE 3.3 on RHEL 7.3 its not required

for node in {ose-master,ose-hub,ose-node1}; do
echo "Installing Docker on $node" && \
ssh $node "sudo yum -y install docker"
ssh $node "sed -i \"/^OPTIONS=/ s:.*:OPTIONS=\'--selinux-enabled --insecure-registry 172.30.0.0\/16\':\" /etc/sysconfig/docker"
scp /home/ec2-user/aws-in-openshift/docker-storage-setup $node:/etc/sysconfig/docker-storage-setup
ssh $node "docker-storage-setup"
ssh $node "chcon -t docker_exec_t /usr/bin/docker*"
ssh $node "chcon -Rt svirt_sandbox_file_t /var/lib"
ssh $node "chcon -Rt svirt_sandbox_file_t /var/db"
ssh $node "systemctl enable docker"
ssh $node "systemctl start docker"
done

###############  Starting Installation #####################

yum -y install atomic-openshift-utils

echo "Change public ip with master public ip ...."

sed -i 's/13.55.135.249/<master public ip>/g' myconfighost
sed -i 's/13.55.135.249/<master public ip>/g' /home/ec2-user/aws-in-openshift/myconfighost

echo "Starting Installation ...."

ansible-playbook -i myconfighost /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
