#!/bin/bash

set -x

export PASS="root"

# Creating Nova databases
mysql -uroot -proot <<EOF
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY '$PASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY '$PASS';
EOF

# Adding Neutron service to Keystone
source admin-openrc

openstack user create --domain default --password $PASS neutron

openstack role add --project service --user neutron admin

openstack service create --name neutron \
  --description "OpenStack Networking" network

openstack endpoint create --region RegionOne \
  network public http://controller:9696

openstack endpoint create --region RegionOne \
  network internal http://controller:9696

openstack endpoint create --region RegionOne \
  network admin http://controller:9696

# Installing Neutron services

yum install -y openstack-neutron openstack-neutron-ml2 \
  openstack-neutron-openvswitch

cp conf/neutron/neutron.conf /etc/neutron/neutron.conf
cp conf/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini 
cp conf/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini
IP=$(ip a s eth0 | grep 'inet ' | awk '{print $2}' | awk -F "/" '{print $1}')
sed -i "/local_ip = / s/$/$IP/" /etc/neutron/plugins/ml2/openvswitch_agent.ini

cp conf/neutron/l3_agent.ini /etc/neutron/l3_agent.ini
cp conf/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
cp conf/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

# Populating Neutron database
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

# Starting Neutron services
systemctl enable openvswitch 
systemctl start openvswitch 
ovs-vsctl --may-exist add-br br-provider

systemctl restart openstack-nova-api.service \
  openstack-nova-compute.service
systemctl enable neutron-server.service \
  neutron-openvswitch-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service neutron-l3-agent.service
systemctl start neutron-server.service \
  neutron-openvswitch-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service neutron-l3-agent.service

