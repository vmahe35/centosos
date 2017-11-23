#!/bin/bash

export PASS="root"

# Creating Heat database
mysql -uroot -proot <<EOF
CREATE DATABASE heat;
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' \
IDENTIFIED BY '$PASS';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' \
IDENTIFIED BY '$PASS';
EOF

# Adding Heat service to Keystone
source admin-openrc

openstack user create --domain default --password $PASS heat

openstack role add --project service --user heat admin

openstack service create --name heat \
  --description "Orchestration" orchestration

openstack service create --name heat-cfn \
  --description "Orchestration"  cloudformation

openstack endpoint create --region RegionOne \
  orchestration public http://controller:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  orchestration internal http://controller:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  orchestration admin http://controller:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  cloudformation public http://controller:8000/v1

openstack endpoint create --region RegionOne \
  cloudformation internal http://controller:8000/v1

openstack endpoint create --region RegionOne \
  cloudformation admin http://controller:8000/v1

openstack domain create --description "Stack projects and users" heat

openstack user create --domain heat --password $PASS heat_domain_admin

openstack role add --domain heat --user-domain heat --user heat_domain_admin admin

openstack role create heat_stack_owner

openstack role add --project demo --user demo heat_stack_owner

openstack role create heat_stack_user

# Installing Heat services
yum install -y openstack-heat-api openstack-heat-api-cfn \
  openstack-heat-engine

cp conf/heat/heat.conf /etc/heat/heat.conf

# Populating Heat database
su -s /bin/sh -c "heat-manage db_sync" heat

# Starting Heat service
systemctl enable openstack-heat-api.service \
  openstack-heat-api-cfn.service openstack-heat-engine.service

systemctl start openstack-heat-api.service \
  openstack-heat-api-cfn.service openstack-heat-engine.service
