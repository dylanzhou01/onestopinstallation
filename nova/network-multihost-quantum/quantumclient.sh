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

sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1

cat <<EOF >  /etc/network/interfaces
auto lo
iface lo inet loopback

#For Exposing OpenStack API over the internet
auto ${COMPUTE_INTERNET_ETH}
iface ${COMPUTE_INTERNET_ETH} inet static
address ${COMPUTE_INTERNET_IP}
netmask ${COMPUTE_INTERNET_NETMASK}
gateway ${COMPUTE_INTERNET_GATEWAY}

# OpenStack management & VM conf
auto ${COMPUTE_MANAGEMENT_ETH}
iface ${COMPUTE_MANAGEMENT_ETH} inet manual
up ifconfig \$IFACE 0.0.0.0 up
up ip link set \$IFACE promisc on
down ip link set \$IFACE promisc off
down ifconfig \$IFACE down

auto br-eth1
iface br-eth1 inet static
address ${COMPUTE_MANAGEMENT_IP}
netmask ${COMPUTE_MANAGEMENT_NETMASK}
EOF

virsh net-destroy default
virsh net-undefine default

apt-get install -y --force-yes openvswitch-switch openvswitch-datapath-dkms
#br-int will be used for VM integration
ovs-vsctl add-br br-int

#br-eth1 will be used for VM configuration
ovs-vsctl add-br br-eth1
ovs-vsctl add-port br-eth1 ${COMPUTE_MANAGEMENT_ETH}

apt-get install -y --force-yes quantum-plugin-openvswitch-agent

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

#the /etc/quantum/quantum.conf:
sed -i -e "
       s/# rabbit_host = localhost/rabbit_host = $CONTROLLER_MANAGEMENT_IP/g;
    " /etc/quantum/quantum.conf
#
service quantum-plugin-openvswitch-agent restart