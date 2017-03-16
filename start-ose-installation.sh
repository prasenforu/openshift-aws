#!/bin/bash

# Installing PAckages for openshift

yum -y install atomic-openshift-utils

# Editing ansible host file

maspubip=`cat /tmp/master-pubip-$USER`

sed -i "s/XXXXXXXXX/$maspubip/g" myconfighost
sed -i "s/XXXXXXXXX/$maspubip/g" /home/ec2-user/aws-in-openshift/myconfighost

# Run ansible playbook

ansible-playbook -i myconfighost /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml

# copy post OSE setup script
scp /home/ec2-user/aws-in-openshift/post-ose-setup.sh  ose-master:/root/
scp /home/ec2-user/aws-in-openshift/reset-ip.sh  ose-master:/root/
ssh ose-master 	"chmod 755 /root/post-ose-setup.sh"
ssh ose-master 	"chmod 755 /root/reset-ip.sh"
