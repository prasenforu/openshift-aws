# Openshift-aws

# Overview
This Quick Start reference deployment guide provides step-by-step instructions for deploying Red Hat OpenShift on the Amazon Web Services (AWS) cloud. 

# OpenShift & AWS Architecture
We will look at the OpenShift v3.x was created to reflect the additional information needed based on some key models below Docker, Kubernetes.
•	DNS: The host that contain Red Hat OpenShift control components, including the API server and the controller manager server. The master manages nodes in its Kubernetes
•	Master: The host that contain Red Hat OpenShift control components, including the API server and the controller manager server. The master manages nodes in its Kubernetes cluster and schedules pods to run on nodes.
•	Hub: The host that contain Red Hat OpenShift registry, router and NFS. This server some people call as Infra Server. This server is important, we will point our wild card DNS “cloudapps.cloud-cafe.in” in godaddy.in in my domain configuration.
•	Node1 and Node2: Nodes provide the runtime environments for containers. Each node in a Kubernetes cluster has the required services to be managed by the master. Nodes also have the required services to run pods, including Docker, a kubelet and a service proxy. 

image

# Prerequisites 
Before you deploy this Quick Start, we recommend that you become familiar with the following AWS services. (If you are new to AWS, see Getting Started with AWS.)

•	Amazon Virtual Private Cloud (Amazon VPC)
•	Amazon Elastic Compute Cloud (Amazon EC2)

It is assumes that familiarity with PaaS concepts and Red Hat OpenShift. For more information, see the Red Hat OpenShift documentation.
If you want to access publically your openshift then you need registered domain. Here I use my domain (cloud-café.in) which I purchase from godaddy.in

Step #1	Subscribe to Red Hat OpenShift
Step #2	Prepare an AWS Account
Step #3	Setup VPC

1.	Configure VPC with 10.90.0.0/16 CIDR	
(Do not use 10.1.0.0/16 or 10.128.0.0/14, this CIDR by default taken by OpenShift for internal communication), 
But there is option if you want to change, see the Red Hat OpenShift documentation.
2.	Create two subnet (Private - 10.90.2.0/24  & Public 10.90.1.0/24)
3.	Create Internet Gate Way (IGW)
4.	Create routing table for internet and associate public subnet and add route with Internet Gate Way
5.	Setup Nat Gate Way and assign public IP and associate with Private Subnet.

Step #4	Setup Security Group

# Deployment Steps

DNS is a requirement for OpenShift Enterprise. In fact most issues comes if you do not have properly working DNS environment.  As we are running in AWS so there is another complex because AWS use its own DNS server on their instances, we need to change make a separate DNS server and use in our environment.

1.	Go to your VPC
2.	Choose your VPC from “Filter by VPC:”
3.	Click “DHCP Option Sets”
4.	Create DHCP Option Set 
5.	Give your domain name “cloud-café-in” in Domain name
6.	Give DNS server IP in Domain name servers.
7.	You can set NTP servers on same DNS server, give DNS server IP in NTP servers (optional).

Now activate your DNS server for your VPC
1.	Now go to your VPC
2.	Choose your VPC from “Filter by VPC:”
3.	Click “Your VPCs”
4.	Select Openshift-VPC
5.	Click Action
6.	Then “Edit DHCP Option Set “
7.	Then Select what you created from earlier.

Now launch an EC2 in Public Subnet with 10.90.1.78 ip 
Add below content in user data in Advance section.

#!/bin/bash
echo nameserver 8.8.8.8 >> /etc/resolv.conf
yum install git unzip -y















# Check status
  
  oc get pods
  oc get all
