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

#cat <<EOF >  /etc/network/interfaces
#auto lo
#iface lo inet loopback

#Not internet connected(used for OpenStack management)
#auto ${CONTROLLER_MANAGEMENT_ETH}
#iface ${CONTROLLER_MANAGEMENT_ETH} inet static
#address ${CONTROLLER_MANAGEMENT_IP}
#netmask ${CONTROLLER_MANAGEMENT_NETMASK}

#For Exposing OpenStack API over the internet
#auto ${CONTROLLER_INTERNET_ETH}
#iface ${CONTROLLER_INTERNET_ETH} inet static
#address ${CONTROLLER_INTERNET_IP}
#netmask ${CONTROLLER_INTERNET_NETMASK}
#gateway ${CONTROLLER_INTERNET_GATEWAY}
#EOF

#service networking restart

apt-get install -y --force-yes vlan bridge-utils

sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1

#install quantum server
apt-get install -y --force-yes quantum-server quantum-plugin-openvswitch
mysql -uroot -p${MYSQL_PASSWD} -e "DROP DATABASE IF EXISTS quantum;"
mysql -uroot -p${MYSQL_PASSWD} -e "DROP USER ${QUANTUM_DB_USER};"
mysql -uroot -p${MYSQL_PASSWD} -e "CREATE DATABASE quantum;"
mysql -uroot -p${MYSQL_PASSWD} -e "GRANT ALL ON quantum.* TO '${QUANTUM_DB_USER}'@'%' IDENTIFIED BY '${QUANTUM_DB_PASSWD}';"

sed -i "s/sqlite:\/\/\/\/var\/lib\/quantum\/ovs.sqlite/mysql:\/\/$QUANTUM_DB_USER:$QUANTUM_DB_PASSWD@$MYSQL_HOST\/quantum/g" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini

function insertToLine(){
   text=$(sed -n "$1p" $3)
   if [[ "$text" != "$2" ]]; then
       sed -i "$1i $2" $3
   fi
}

insertToLine 25 "tenant_network_type=vlan" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
insertToLine 37 "network_vlan_ranges = ${VLAN_PHYSICAL_NET}:101:199" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini

sed -i -e "
       s/127.0.0.1/$CONTROLLER_MANAGEMENT_IP/g;
       s/%SERVICE_TENANT_NAME%/$SERVICE_TENANT_NAME/g;
       s/%SERVICE_USER%/quantum/g;
       s/%SERVICE_PASSWORD%/$SERVICE_PASSWORD/g;
    " /etc/quantum/api-paste.ini

service quantum-server restart