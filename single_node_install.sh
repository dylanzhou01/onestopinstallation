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
get_images

#Create a simple credential file and load it so you won't be bothered later:
#keystone_basic.sh & keystone_endpoints_basic.sh need these parameters
create_credential
source /etc/profile

source $STACK_DIR/apt/offline.sh
source $STACK_DIR/rabbitmq/install.sh
source $STACK_DIR/mysql/install.sh
source $STACK_DIR/keystone/install.sh
source $STACK_DIR/glance/install.sh
source $STACK_DIR/cinder/install.sh
source $STACK_DIR/nova/network-singlehost-dhcp/install.sh
source $STACK_DIR/horizon/install.sh

# Some configuration for single mode only
create_cinder_volume
create_glance_image
create_nova_network