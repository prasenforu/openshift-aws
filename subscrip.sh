#!/bin/bash

# Setting RedHat subscription on all hosts
# Add your username, password & Pool id

for node in {ose-master,ose-hub,ose-node1,ose-node2}; do
echo "Setting RedHat subscription on $node" && \
ssh $node "subscription-manager register --username=########  --password='#######'"
ssh $node "subscription-manager attach --pool=##################"
ssh $node "subscription-manager repos --disable='*'"
ssh $node "subscription-manager repos --enable=rhel-7-server-rpms' --enable='rhel-7-server-extras-rpms' --enable='rhel-7-server-ose-3.4-rpms'"
done 
