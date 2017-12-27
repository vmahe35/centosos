#!/bin/bash

# Installing Horizon
yum install -y openstack-dashboard

cp conf/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings
cp conf/httpd/conf.d/openstack-dashboard.conf /etc/httpd/conf.d/openstack-dashboard.conf

# Restart services
systemctl restart httpd.service memcached.service
