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

# Starting OSE installation

yum -y install atomic-openshift-utils
ansible-playbook -i /home/ec2-user/aws-in-openshift/myconfighost /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
