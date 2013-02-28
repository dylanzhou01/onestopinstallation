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

stop nova-network

ip link set br2 down
brctl delbr br2

ip link set br3 down
brctl delbr br3

ip link set br200 down
brctl delbr br200

ip link set br201 down
brctl delbr br201

killall dnsmasq

virsh net-destroy default
virsh net-undefine default

#flush and clear rules
iptables -F
iptables -Z
iptables -X

iptables -t nat -F
iptables -t nat -Z
iptables -t nat -X