#!/bin/bash

source admin-openrc

# Creating provider network
openstack network create  --share --external \
  --provider-physical-network provider \
  --provider-network-type flat provider

ip address add 172.16.0.1/24 dev br-provider
ip link set up dev br-provider

openstack subnet create --network provider \
  --allocation-pool start=172.16.0.201,end=172.16.0.250 \
  --dns-nameserver 10.193.21.160 --gateway 172.16.0.1 \
  --subnet-range 172.16.0.0/24 provider

iptables -t nat -I POSTROUTING 1 -s 172.16.0.0/24 -j MASQUERADE

# Creating 2 Self-Service networks
openstack network create selfservice

openstack subnet create --network selfservice \
  --dns-nameserver 10.193.21.160 --gateway 10.0.0.1 \
  --subnet-range 10.0.0.0/24 selfservice-subnet

openstack network create selfservice2

openstack subnet create --network selfservice2 \
  --dns-nameserver 10.193.21.160 --gateway 10.0.1.1 \
  --subnet-range 10.0.1.0/24 selfservice2-subnet

# Creating router and ports to networks
openstack router create router

openstack router add subnet router selfservice-subnet
openstack router add subnet router selfservice2-subnet

openstack router set --external-gateway provider router

# Creating nano flavor
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano

# Opening ICMP and SSH ports in security group default
openstack security group create secgroup --description "Allowing ICMP and SSH"
openstack security group rule create --proto icmp secgroup
openstack security group rule create --proto tcp --dst-port 22 secgroup


# Creating two CirrOS instances
openstack server create --flavor m1.nano --image cirros --nic net-id=selfservice --security-group secgroup --key-name mykey cirrhose1
openstack server create --flavor m1.nano --image cirros --nic net-id=selfservice2 --security-group secgroup --key-name mykey cirrhose2
