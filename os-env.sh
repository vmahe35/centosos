#!/bin/bash

export PASS="root"

# Installing NTP server
yum install -y chrony

cp conf/chrony.conf /etc/chrony.conf

systemctl enable chronyd.service
systemctl start chronyd.service


# Installing RDO repositories
yum install -y centos-release-openstack-queens
yum install -y https://rdoproject.org/repos/rdo-release.rpm
yum upgrade -y
yum install -y python-openstackclient
yum install -y openstack-selinux


# Installing MySQL database
yum install -y mariadb mariadb-server python2-PyMySQL

cp conf/my.cnf.d/openstack.cnf /etc/my.cnf.d/openstack.cnf

systemctl enable mariadb.service
systemctl start mariadb.service

mysql -uroot <<EOF
UPDATE mysql.user SET Password=PASSWORD('root') WHERE User='root';
DELETE FROM mysql.user WHERE user='root' AND host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE user='';
DROP DATABASE test;
FLUSH PRIVILEGES;
EOF

# Installing RabbitMQ
yum install -y rabbitmq-server
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service
rabbitmqctl add_user openstack $PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# Installing Memcached
yum install -y memcached python-memcached
cp conf/sysconfig/memcached /etc/sysconfig/memcached
systemctl enable memcached.service
systemctl start memcached.service
