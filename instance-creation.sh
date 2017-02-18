#!/bin/bash

# Instance Creation and docker volume setup

# Variable declare

iid=ami-39ac915a
ity=t2.medium
knm=prasen
subprid=subnet-5861ed2e
subpuid=subnet-84f095e0
sgidm=sg-258d5642
sgidh=sg-3b59fe5c
sgidn=sg-7959fe1e 
volsz=10

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
--subnet-id $subpuid --private-ip-address 10.90.1.210 

# NDOE2 Server

echo "Starting OSE NODE-2 Host .."

#aws ec2 run-instances --image-id $iid --count 1 \
#--instance-type $ity --key-name $knm --security-group-ids $sgidn \
#--subnet-id $subprid --private-ip-address 10.90.2.211
