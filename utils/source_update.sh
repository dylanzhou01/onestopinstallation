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

SOURCE_FILE=${SOURCE_FILE:-"/etc/apt/sources.list"}
cp $SOURCE_FILE $SOURCE_FILE.163.bak
cat <<APT >$SOURCE_FILE
deb http://mirrors.163.com/ubuntu/ precise main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ precise-backports restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ precise-proposed main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ precise-security main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ precise-updates main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise-backports main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise-proposed main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise-security main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise-updates main restricted universe multiverse
APT

if [ ! -e /etc/apt/sources.list.d ]; then
 mkdir /etc/apt/sources.list.d
fi

cat <FOLSOM > /etc/apt/sources.list.d/folsom.list
deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/folsom main
FOLSOM

sudo apt-get install -y --force-yes ubuntu-cloud-keyring
sudo apt-get -y --force-yes update
sudo apt-get -y --force-yes dist-upgrade

# Software to make source file
sudo apt-get install -y --force-yes dpkg-dev

# All openstack softwares
sudo apt-get -d install vsftpd dos2unix
sudo apt-get -d install ntp
sudo apt-get -d install rabbitmq-server
sudo apt-get -d install mysql-server python-mysqldb
sudo apt-get -d install keystone curl openssl
sudo apt-get -d install glance
sudo apt-get -d install cinder-api cinder-scheduler cinder-volume open-iscsi python-cinderclient tgt
sudo apt-get -d install nova-api nova-cert novnc nova-consoleauth nova-scheduler nova-novncproxy nova-doc bridge-utils nova-network nova-compute vlan nova-api-metadata nova-compute-kvm
sudo apt-get -d install openvswitch-switch openvswitch-datapath-dkms quantum-plugin-openvswitch-agent quantum-dhcp-agent quantum-l3-agent quantum-server quantum-plugin-openvswitch
sudo apt-get -d install memcached libapache2-mod-wsgi openstack-dashboard

if [ ! -e /software ]; then
 mkdir /software
fi 
sudo cp /var/cache/apt/archives/*.deb  /software
sudo cp /var/cache/apt/archives/lock  /software

sudo dpkg-scanpackages /software /dev/null | gzip>/software/Packages.gz

if [ ! -e /resource ]; then
 mkdir /resource
fi

tar -zcvf /resource/software`date +%Y%m%d`.tar.gz /software/*
