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
source $STACK_DIR/nova/network-multihost-quantum/quantumclient.sh


apt-get install -y --force-yes kvm libvirt-bin pm-utils
#cat <<EOF>>/etc/libvirt/qemu.conf
#cgroup_device_acl = [
#    "/dev/null", "/dev/full", "/dev/zero",
#    "/dev/random", "/dev/urandom",
#    "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
#    "/dev/rtc", "/dev/hpet","/dev/net/tun",
#]
#EOF
#sed -i '/#listen_tls/s/#listen_tls/listen_tls/; 
#        /#listen_tcp/s/#listen_tcp/listen_tcp/; 
#        /#auth_tcp/s/#auth_tcp/auth_tcp/; 
#        /auth_tcp/s/sasl/none/'  /etc/libvirt/libvirtd.conf
#        
#sed -i '/env libvirtd_opts/s/-d/-d –l/' /etc/init/libvirt-bin.conf
#
#sed -i '/libvirtd_opts/s/-d/-d -l/' /etc/default/libvirt-bin

apt-get install -y --force-yes nova-compute-kvm

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
libvirt_ovs_bridge=br-int
libvirt_vif_type=ethernet
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
libvirt_use_virtio_for_bridges=True
start_guests_on_host_boot=True
resume_guests_state_on_host_boot=True
api_paste_config=/etc/nova/api-paste.ini
allow_admin_api=True
use_deprecated_auth=False
nova_url=http://$CONTROLLER_MANAGEMENT_IP:8774/v1.1/
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf
connection_type=libvirt

# APIS
ec2_host=$CONTROLLER_MANAGEMENT_IP
ec2_url=http://$CONTROLLER_MANAGEMENT_IP:8773/services/Cloud
keystone_ec2_url=http://$CONTROLLER_MANAGEMENT_IP:5000/v2.0/ec2tokens
s3_host=$CONTROLLER_MANAGEMENT_IP
cc_host=$CONTROLLER_MANAGEMENT_IP
metadata_host=$CONTROLLER_MANAGEMENT_IP
dmz_cidr=$CONTROLLER_MANAGEMENT_IP
my_ip=$COMPUTE_MANAGEMENT_IP


# RABBITMQ
rabbit_host=$CONTROLLER_MANAGEMENT_IP

# GLANCE
image_service=nova.image.glance.GlanceImageService
glance_api_servers=$CONTROLLER_MANAGEMENT_IP:9292

# Network settings
network_api_class=nova.network.quantumv2.api.API
quantum_url=http://$CONTROLLER_MANAGEMENT_IP:9696
quantum_auth_strategy=keystone
quantum_admin_tenant_name=$SERVICE_TENANT_NAME
quantum_admin_username=quantum
quantum_admin_password=$SERVICE_PASSWORD
quantum_admin_auth_url=http://$CONTROLLER_MANAGEMENT_IP:35357/v2.0
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver

# NOVNC CONSOLE
novnc_enabled=True
novncproxy_base_url=http://$CONTROLLER_MANAGEMENT_IP:6080/vnc_auto.html

# Change vncserver_proxyclient_address and vncserver_listen to match each compute host
vncserver_proxyclient_address=$COMPUTE_MANAGEMENT_IP
vncserver_listen=0.0.0.0
EOF

# restart networking to refresh the route
service networking restart

cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done
