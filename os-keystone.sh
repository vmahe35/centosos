#!/bin/bash

set -x

export PASS="root"

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
