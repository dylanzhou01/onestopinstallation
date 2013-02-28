#!/bin/bash
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

mysql -uroot -pu7i8o9p0 << EOF
use nova;
DELETE a FROM nova.security_group_instance_association AS a INNER JOIN nova.instances AS b ON a.instance_uuid=b.uuid where b.uuid='$1';
DELETE FROM nova.instance_info_caches WHERE instance_uuid='$1';
DELETE FROM nova.instance_faults WHERE instance_uuid='$1';
DELETE FROM nova.instance_metadata WHERE instance_uuid='$1';
DELETE FROM nova.instance_system_metadata WHERE instance_uuid='$1';
DELETE FROM nova.virtual_interfaces WHERE instance_uuid='$1';
DELETE FROM nova.fixed_ips WHERE instance_uuid='$1';
DELETE FROM nova.volumes WHERE instance_uuid='$1';
DELETE FROM nova.instance_id_mappings WHERE uuid='$1';
DELETE FROM nova.instances WHERE uuid='$1';
EOF