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
apt-get install -y --force-yes glance

#Prepare a Mysql database for Glance:
mysql -uroot -p${MYSQL_PASSWD} -e "DROP DATABASE IF EXISTS glance;"
mysql -uroot -p${MYSQL_PASSWD} -e "DROP USER ${GLANCE_DB_USER};"
mysql -uroot -p${MYSQL_PASSWD} -e "CREATE DATABASE glance;"
mysql -uroot -p${MYSQL_PASSWD} -e "GRANT ALL ON glance.* TO '${GLANCE_DB_USER}'@'%' IDENTIFIED BY '${GLANCE_DB_PASSWD}';"
mysql -uroot -p${MYSQL_PASSWD} -e "GRANT ALL ON glance.* TO '${GLANCE_DB_USER}'@'localhost' IDENTIFIED BY '${GLANCE_DB_PASSWD}';"

sed -i -e "
       s/127.0.0.1/$GLANCE_HOST/g;
       s/%SERVICE_TENANT_NAME%/$SERVICE_TENANT_NAME/g;
       s/%SERVICE_USER%/glance/g;
       s/%SERVICE_PASSWORD%/$SERVICE_PASSWORD/g;
    " /etc/glance/glance-api.conf

sed -i -e "
       s/127.0.0.1/$GLANCE_HOST/g;
       s/%SERVICE_TENANT_NAME%/$SERVICE_TENANT_NAME/g;
       s/%SERVICE_USER%/glance/g;
       s/%SERVICE_PASSWORD%/$SERVICE_PASSWORD/g;
    " /etc/glance/glance-registry.conf

add_config "config_file = /etc/glance/glance-api-paste.ini" "/etc/glance/glance-api.conf"
add_config "flavor=keystone" "/etc/glance/glance-api.conf" 
add_config "config_file = /etc/glance/glance-registry-paste.ini" "/etc/glance/glance-registry.conf"
add_config "flavor=keystone" "/etc/glance/glance-registry.conf"

GLANCE_API_CONF=${GLANCE_API_CONF:-"/etc/glance/glance-api.conf"}
GLANCE_REGISTRY_CONF=${GLANCE_REGISTRY_CONF:-"/etc/glance/glance-registry.conf"}
sed -i '/sql_connection = .*/{s|sqlite:///.*|mysql://'"$GLANCE_DB_USER"':'"$GLANCE_DB_PASSWD"'@'"$MYSQL_HOST"'/glance|g}' $GLANCE_API_CONF
sed -i '/sql_connection = .*/{s|sqlite:///.*|mysql://'"$GLANCE_DB_USER"':'"$GLANCE_DB_PASSWD"'@'"$MYSQL_HOST"'/glance|g}' $GLANCE_REGISTRY_CONF

glance-manage version_control 0
glance-manage db_sync
service glance-api restart
service glance-registry restart
