#!/usr/bin/env bash
#
#    Copyright (C) 2013 Intel Corporation.  All rights reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
set -o xtrace

source $STACK_DIR/localrc
source $STACK_DIR/utils/functions

#Install the required packages:
apt-get install -y --force-yes cinder-api cinder-scheduler cinder-volume open-iscsi python-cinderclient tgt

#Prepare a Mysql database for Cinder:
mysql -uroot -p${MYSQL_PASSWD} -e "DROP DATABASE IF EXISTS cinder;"
mysql -uroot -p${MYSQL_PASSWD} -e "DROP USER ${CINDER_DB_USER};"
mysql -uroot -p${MYSQL_PASSWD} -e "CREATE DATABASE cinder;"
mysql -uroot -p${MYSQL_PASSWD} -e "GRANT ALL ON cinder.* TO '${CINDER_DB_USER}'@'%' IDENTIFIED BY '${CINDER_DB_PASSWD}';"
mysql -uroot -p${MYSQL_PASSWD} -e "GRANT ALL ON cinder.* TO '${CINDER_DB_USER}'@'localhost' IDENTIFIED BY '${CINDER_DB_PASSWD}';"

#Configure /etc/cinder/api-paste.ini like the following:

sed -i -e "
       s/service_host = 127.0.0.1/service_host = $CINDER_HOST/g;
       s/auth_host = 127.0.0.1/auth_host = $AUTH_HOST/g;
       s/%SERVICE_TENANT_NAME%/$SERVICE_TENANT_NAME/g;
       s/%SERVICE_USER%/cinder/g;
       s/%SERVICE_PASSWORD%/$SERVICE_PASSWORD/g;
    " /etc/cinder/api-paste.ini

add_config "sql_connection = mysql://${CINDER_DB_USER}:${CINDER_DB_PASSWD}@$MYSQL_HOST/cinder" "/etc/cinder/cinder.conf"
add_config "osapi_volume_listen_port = 8777" "/etc/cinder/cinder.conf"
add_config "include /var/lib/cinder/volumes/*" "/etc/tgt/conf.d/cinder.conf"

restart tgt

#Then, synchronize your database:
cinder-manage db sync

service cinder-volume restart
service cinder-api restart
service cinder-scheduler restart