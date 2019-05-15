#!/bin/bash

set -x

export PASS="root"

# Creating Glance database
mysql -uroot -proot <<EOF
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
IDENTIFIED BY '$PASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
IDENTIFIED BY '$PASS';
EOF

# Adding Glance service to Keystone
source admin-openrc

openstack user create --domain default --password $PASS glance

openstack role add --project service --user glance admin

openstack service create --name glance \
  --description "OpenStack Image" image

openstack endpoint create --region RegionOne \
  image public http://controller:9292

openstack endpoint create --region RegionOne \
  image internal http://controller:9292

openstack endpoint create --region RegionOne \
  image admin http://controller:9292


# Installing Glance
yum install -y openstack-glance

cp conf/glance/glance-api.conf /etc/glance/glance-api.conf
cp conf/glance/glance-registry.conf /etc/glance/glance-registry.conf

# Populating DB
su -s /bin/sh -c "glance-manage db_sync" glance

# Starting Glance service
systemctl enable openstack-glance-api.service \
  openstack-glance-registry.service
systemctl start openstack-glance-api.service \
  openstack-glance-registry.service


# Uploading CirrOS image
yum install -y wget
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

openstack image create "cirros" \
  --file cirros-0.4.0-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --public

