#!/bin/bash

set -x

export OS_CLOUD=openstack

# Upload the Ubuntu 18.04 VM image (only if not done yet in your tenant)
openstack --insecure image create "ubuntu-18-04" --file ~/images/bionic-server-cloudimg-amd64.img --disk-format qcow2 --container-format bare

# Creating 2 Self-Service networks
openstack --insecure network create selfservice

openstack --insecure subnet create --network selfservice \
  --dns-nameserver 10.193.21.160 --gateway 10.0.0.1 \
  --subnet-range 10.0.0.0/24 selfservice-subnet

# Creating router and ports to networks
openstack --insecure router create router

openstack --insecure router add subnet router selfservice-subnet

openstack --insecure router set --external-gateway external router

# Opening ICMP and SSH ports in security group default
openstack --insecure security group create secgroup --description "Allowing ICMP and SSH"
openstack --insecure security group rule create --proto icmp secgroup
openstack --insecure security group rule create --proto tcp --dst-port 22 secgroup

# Create a keypair and upload it
# ssh-keygen -b 2048 -t rsa -q -N "" -f ./mykey
openstack --insecure keypair create --public-key ~/keys/magellan_training_key.pub magellan_training_key

## If you use the default Openstack project for Magellan training, uncomment these lines
## Creating VM instances with Ubuntu 18.04 server system + Proxy settings + Python + Docker + some ssh public keys
# openstack --insecure server create --flavor m1.tiny --image "Ubuntu-18.04-with-Docker-and-Python" --nic net-id=selfservice --security-group secgroup --key-name magellan_training_key bastion
# openstack --insecure server create --flavor m1.tiny --image "Ubuntu-18.04-with-Docker-and-Python" --nic net-id=selfservice --security-group secgroup --key-name magellan_training_key ubuntu-01

## If your own Openstack project, uncomment these lines
## Creating VM instances with only a basic Ubuntu 18.04 server OS
# openstack --insecure server create --flavor m1.tiny --image "ubuntu-18-04" --nic net-id=selfservice --security-group secgroup --key-name magellan_training_key bastion
# openstack --insecure server create --flavor m1.tiny --image "ubuntu-18-04" --nic net-id=selfservice --security-group secgroup --key-name magellan_training_key ubuntu-01
