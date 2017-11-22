#!/bin/bash

export PASS="root"

# Creating Keystone database
mysql -uroot -proot <<EOF
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY '$PASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY '$PASS';
EOF

# Installing Keystone
yum install -y openstack-keystone httpd mod_wsgi

cp conf/keystone/keystone.conf /etc/keystone/keystone.conf

# Populating DB
su -s /bin/sh -c "keystone-manage db_sync" keystone

# Initializing Keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password $PASS \
  --bootstrap-admin-url http://controller:35357/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

cp conf/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

systemctl enable httpd.service
systemctl start httpd.service

# Creating projects, users, and roles
source admin-openrc

openstack project create --domain default \
  --description "Service Project" service

openstack project create --domain default \
  --description "Demo Project" demo

openstack user create --domain default \
  --password $PASS demo

openstack role create user

openstack role add --project demo --user demo user


