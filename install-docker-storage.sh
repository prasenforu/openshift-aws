#!/bin/bash

# Install Openshift 3.3 packages

ssh ose-master "yum -y install wget git net-tools bind-utils iptables-services bridge-utils pythonvirtualenv gcc bash-completion"

# yum update on the master and all the nodes:

for node in {ose-master,ose-hub,ose-node1,ose-node2}; do
echo "Running yum update on $node" && \
ssh $node "echo 'nameserver 8.8.8.8' | sudo tee --append /etc/resolv.conf"
ssh $node "yum -y update"
ssh $node "yum install -y wget git net-tools bind-utils"
done

# Install docker in all hosts.
# Below chcon only it you OSE 3.3 on RHEL 7.3
# OSE 3.3 on RHEL 7.3 its not required

for node in {ose-master,ose-hub,ose-node1,ose-node2}; do
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

# Rebooting servers

for node in {ose-master,ose-hub,ose-node1,ose-node2}; do
echo "Rebooting $node" && \
ssh $node reboot
done

echo "Waiting for servers up ...."
sleep 200
