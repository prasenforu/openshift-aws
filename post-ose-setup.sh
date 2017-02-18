#!/bin/bash

# Post installation

admpas=admin2675
userpas=tcs2675

# Backup config file
cp /etc/origin/master/master-config.yaml /etc/origin/master/master-config.yaml.original

# Get all nodes details

oc get nodes
oc get nodes --show-labels

# Set hosts proper levels

oc label node ose-hub.cloud-cafe.in region="infra" zone="infranodes" --overwrite
oc label node ose-node1.cloud-cafe.in region="primary" zone="east" --overwrite
#oc label node ose-node2.cloud-cafe.in region="primary" zone="west" –overwrite

# Check all nodes details are updated

oc get nodes
oc get nodes --show-labels

# Edit /etc/origin/master/master-config.yaml and Set defaultNodeSelector like defaultNodeSelector: "region=primary"

sed -i 's/  defaultNodeSelector: ""/  defaultNodeSelector: "region=primary"/' /etc/origin/master/master-config.yaml

# Restart openshift services master

systemctl restart atomic-openshift-master
systemctl status atomic-openshift-master

# Setting Authentication openshift

yum install -y httpd-tools
htpasswd -c /etc/origin/master/users.htpasswd admin $admpas
htpasswd /etc/origin/master/users.htpasswd pkar $userpas

# There are some security problem with router, 
# so need to delete router deployment then 
# Setup Router separately 

oc delete dc/router rc/router-1 svc/router po/router-1-deploy
oadm policy add-cluster-role-to-user cluster-admin admin
oadm policy add-scc-to-user privileged system:serviceaccount:default:registry
systemctl restart atomic-openshift-master
systemctl status atomic-openshift-master
oadm router router --replicas=1 --selector='region=infra' --credentials='/etc/origin/master/openshift-router.kubeconfig' --service-account=router --stats-password=$admpas
