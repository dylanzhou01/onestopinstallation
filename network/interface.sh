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

cat <<EOF >>  /etc/network/interfaces
auto lo
iface lo inet loopback

#Not internet connected(used for OpenStack management)
auto ${MANAGEMENT_ETH}
iface ${MANAGEMENT_ETH} inet static
address ${MANAGEMENT_IP}
netmask ${MANAGEMENT_NETMASK}

#For Exposing OpenStack API over the internet
auto ${INTERNET_ETH}
iface ${INTERNET_ETH} inet static
address ${INTERNET_IP}
netmask ${INTERNET_NETMASK}
EOF

