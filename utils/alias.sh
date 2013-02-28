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

cat <<EOF > ~/.bash_aliases
alias cdtop='cd /usr/share/pyshared/nova'
alias cdhome='cd $STACK_DIR'
alias cdnova='cd /var/lib/nova/instances'
alias cdlog='cd /var/log/nova'
alias startall='$STACK_DIR/utils/startall.sh'
alias stopall='$STACK_DIR/utils/stopall.sh'
alias novaconf='vi /etc/nova/nova.conf'
alias vclog='vi /var/log/nova/nova-compute.log'
alias vnlog='vi /var/log/nova/nova-network.log'
alias valog='vi /var/log/nova/nova-api.log'
alias clearlog='$STACK_DIR/utils/clearlog.sh'
alias clearinstance='$STACK_DIR/utils/clearinstance.sh'
alias clearnet='$STACK_DIR/utils/clearnetwork.sh'
alias cleardb='$STACK_DIR/utils/cleardb.sh'
alias showerror='grep "error" /var/log/nova/*.log'
EOF

source ~/.bash_aliases