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

# copy the software files
echo "copying the software.tar.gz file"
mkdir /home/openstack
#cp /root/usb/software.tar.gz /home/openstack/software.tar.gz
cd /home/openstack
tar zxvf software.tar.gz

#change apt source list
SOURCE_FILE=${SOURCE_FILE:-"/etc/apt/sources.list"}
cp $SOURCE_FILE $SOURCE_FILE.bak
cat <<APT >$SOURCE_FILE
deb file:/// home/openstack/software/
APT

apt-get update -y --force-yes
apt-get dist-upgrade -y --force-yes