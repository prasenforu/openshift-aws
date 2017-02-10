#!/bin/bash

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

echo "Waiting for servers up ...."
sleep 200

# Configuring Repo

for node in {ose-master,ose-hub,ose-node1}; do
echo "Deploy Openshift Repo on $node" && \
scp /etc/yum.repos.d/open.repo $node:/etc/yum.repos.d/open.repo
scp /etc/resolv.conf $node:/etc/resolv.conf
yum clean all
yum repolist
done

# Rebooting servers

for node in {ose-master,ose-hub,ose-node1}; do
echo "Rebooting $node" && \
ssh $node reboot
done