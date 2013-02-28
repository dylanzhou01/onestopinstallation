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

apt-get install -y --force-yes bridge-utils nova-network nova-compute nova-api-metadata

#Fix the error:
#open /dev/kvm: Permission denied
#Could not initialize KVM, will disable KVM support
sed -i "s/#user = \"root\"/user = \"root\"/g" /etc/libvirt/qemu.conf
sed -i "s/#group = \"root\"/group = \"root\"/g" /etc/libvirt/qemu.conf
service libvirt-bin restart

#The whole nova.conf
cat <<EOF > /etc/nova/nova.conf
[DEFAULT]
# LOGS/STATE
verbose=True
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/run/lock/nova

# AUTHENTICATION
auth_strategy=keystone

# SCHEDULER
scheduler_driver=nova.scheduler.multi.MultiScheduler
compute_scheduler_driver=nova.scheduler.filter_scheduler.FilterScheduler

# CINDER
volume_api_class=nova.volume.cinder.API

# DATABASE
sql_connection=mysql://$NOVA_DB_USER:$NOVA_DB_PASSWD@$MYSQL_HOST/nova

# COMPUTE
libvirt_type=kvm
libvirt_use_virtio_for_bridges=True
start_guests_on_host_boot=True
resume_guests_state_on_host_boot=True
api_paste_config=/etc/nova/api-paste.ini
allow_admin_api=True
use_deprecated_auth=False
nova_url=http://$CONTROLLER_MANAGEMENT_IP:8774/v1.1/
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf

# APIS
ec2_host=$CONTROLLER_MANAGEMENT_IP
ec2_url=http://$CONTROLLER_MANAGEMENT_IP:8773/services/Cloud
keystone_ec2_url=http://$CONTROLLER_MANAGEMENT_IP:5000/v2.0/ec2tokens
s3_host=$CONTROLLER_MANAGEMENT_IP
cc_host=$CONTROLLER_MANAGEMENT_IP
metadata_host=$COMPUTE_MANAGEMENT_IP
dmz_cidr=$COMPUTE_MANAGEMENT_IP
my_ip=$COMPUTE_MANAGEMENT_IP


# RABBITMQ
rabbit_host=$CONTROLLER_MANAGEMENT_IP

# GLANCE
image_service=nova.image.glance.GlanceImageService
glance_api_servers=$CONTROLLER_MANAGEMENT_IP:9292

# NETWORK
network_manager=nova.network.manager.FlatDHCPManager
force_dhcp_release=True
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver
public_interface=$COMPUTE_MANAGEMENT_ETH
flat_interface=$COMPUTE_VM_ETH
flat_network_bridge=br100
fixed_range=$FIXIP_RANGE
network_size=$NETWORK_SIZE
flat_network_dhcp_start=$DHCP_START
flat_injected=False
connection_type=libvirt
multi_host=True

# NOVNC CONSOLE
novnc_enabled=True
novncproxy_base_url=http://$CONTROLLER_MANAGEMENT_IP:6080/vnc_auto.html
vncserver_proxyclient_address=$COMPUTE_MANAGEMENT_IP
vncserver_listen=$COMPUTE_MANAGEMENT_IP
EOF

sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1

service nova-compute restart
service nova-network restart
service nova-api-meta restart

#change the IP table, please refer to
#https://github.com/mseknibilel/OpenStack-Folsom-Install-guide/issues/14
#https://access.redhat.com/knowledge/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Virtualization_Host_Configuration_and_Guest_Installation_Guide/ch11s02.html
iptables -A POSTROUTING -t mangle -p udp --dport 68 -j CHECKSUM --checksum-fill