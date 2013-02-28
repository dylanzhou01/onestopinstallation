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

mysql -uroot -p$MYSQL_PASSWD -e "DROP DATABASE IF EXISTS glance;"
mysql -uroot -p${MYSQL_PASSWD} -e "CREATE DATABASE glance;"
mysql -uroot -p${MYSQL_PASSWD} -e "GRANT ALL ON glance.* TO '${GLANCE_DB_USER}'@'%' IDENTIFIED BY '${GLANCE_DB_PASSWD}';"


glance-manage db_sync
service glance-api restart && service glance-registry restart

source /etc/profile
glance image-create --name cirros-0.3.0-x86_64 --is-public true --container-format bare --disk-format qcow2 < $STACK_DIR/glance/cirros-0.3.0-x86_64-disk.img
glance image-create --name precise-server-cloudimg-amd64 --is-public true --container-format bare --disk-format qcow2 < $STACK_DIR/glance/precise-server-cloudimg-amd64-disk1.img
