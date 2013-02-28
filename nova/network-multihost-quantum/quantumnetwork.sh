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
export STACK_DIR="/home/openstack/easystack"

if [ -e $STACK_DIR/localrc ]; then
 source $STACK_DIR/localrc
else
 echo "$STACK_DIR/localrc file doesn't exist"
 exit 1
fi

source $STACK_DIR/utils/functions

# get image file and software.tar.gz file
get_software_source

#Create a simple credential file and load it so you won't be bothered later:
#keystone_basic.sh & keystone_endpoints_basic.sh need these parameters
create_credential
source /etc/profile

$STACK_DIR/apt/offline.sh
$STACK_DIR/ntp/compute.sh

apt-get install -y --force-yes vlan bridge-utils

sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1

cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

# VM internet Access
auto ${NETWORK_INTERNET_ETH}
iface ${NETWORK_INTERNET_ETH} inet static
address ${NETWORK_INTERNET_IP}
netmask ${NETWORK_INTERNET_NETMASK}
gateway ${NETWORK_INTERNET_GATEWAY}

# OpenStack management & VM conf
auto ${NETWORK_MANAGEMENT_ETH}
iface ${NETWORK_MANAGEMENT_ETH} inet manual
up ifconfig \$IFACE 0.0.0.0 up
up ip link set \$IFACE promisc on
down ip link set \$IFACE promisc off
down ifconfig \$IFACE down

auto br-eth1
iface br-eth1 inet static
address ${NETWORK_MANAGEMENT_IP}
netmask ${NETWORK_MANAGEMENT_NETMASK}
EOF

apt-get install -y --force-yes openvswitch-switch openvswitch-datapath-dkms
#br-int will be used for VM integration
ovs-vsctl add-br br-int

#br-eth1 will be used for VM configuration
ovs-vsctl add-br br-eth1
ovs-vsctl add-port br-eth1 ${NETWORK_MANAGEMENT_ETH}

#br-ex is used to make to VM accessible from the internet
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex ${NETWORK_INTERNET_ETH}

apt-get install -y --force-yes quantum-plugin-openvswitch-agent quantum-dhcp-agent quantum-l3-agent

sed -i -e "
       s/127.0.0.1/$CONTROLLER_MANAGEMENT_IP/g;
       s/%SERVICE_TENANT_NAME%/$SERVICE_TENANT_NAME/g;
       s/%SERVICE_USER%/quantum/g;
       s/%SERVICE_PASSWORD%/$SERVICE_PASSWORD/g;
    " /etc/quantum/api-paste.ini

#/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
sed -i "s/sqlite:\/\/\/\/var\/lib\/quantum\/ovs.sqlite/mysql:\/\/$QUANTUM_DB_USER:$QUANTUM_DB_PASSWD@$MYSQL_HOST\/quantum/g" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini

function insertToLine(){
   text=$(sed -n "$1p" $3)
   if [[ "$text" != "$2" ]]; then
       sed -i "$1i $2" $3
   fi
}

insertToLine 25 "tenant_network_type=vlan" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
insertToLine 37 "network_vlan_ranges = ${VLAN_PHYSICAL_NET}:101:199" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
insertToLine 80 "bridge_mappings = ${VLAN_PHYSICAL_NET}:br-eth1" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini

#the /etc/quantum/l3_agent.ini:
sed -i -e "
       s/localhost/$CONTROLLER_MANAGEMENT_IP/g;
       s/%SERVICE_TENANT_NAME%/$SERVICE_TENANT_NAME/g;
       s/%SERVICE_USER%/quantum/g;
       s/%SERVICE_PASSWORD%/$SERVICE_PASSWORD/g;
       s/# metadata_ip =/metadata_ip = $CONTROLLER_INTERNET_IP/g;
       s/# metadata_port = 8775/metadata_port = 8775/g;
    " /etc/quantum/l3_agent.ini
#the /etc/quantum/quantum.conf:
sed -i -e "
       s/# rabbit_host = localhost/rabbit_host = $CONTROLLER_MANAGEMENT_IP/g;
    " /etc/quantum/quantum.conf

#restart networking to refresh route
ifconfig br-ex up
service networking restart

# Update route information, so the network node can connect to the internet
route add -net ${NETWORK_INTERNET_NETWORK} netmask ${NETWORK_INTERNET_NETMASK} dev br-ex
route add default gw ${NETWORK_INTERNET_GATEWAY} dev br-ex
route del default gw ${NETWORK_INTERNET_GATEWAY} dev ${NETWORK_INTERNET_ETH}

# Update /etc/rc.local file to make the configuration of route right after restarting network node
cat <<EOF >/etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
ifconfig br-ex up
route add -net ${NETWORK_INTERNET_NETWORK} netmask ${NETWORK_INTERNET_NETMASK} dev br-ex
route add default gw ${NETWORK_INTERNET_GATEWAY} dev br-ex
route del default gw ${NETWORK_INTERNET_GATEWAY} dev ${NETWORK_INTERNET_ETH}
exit 0
EOF

service quantum-plugin-openvswitch-agent restart
service quantum-dhcp-agent restart
service quantum-l3-agent restart