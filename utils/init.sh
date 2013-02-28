#!/usr/bin/env bash

nova-manage network create private --fixed_range_v4=192.168.1.129/25 --num_networks=1 --bridge=br100 --bridge_interface=eth1 --network_size=128 --multi_host=T

sysctl -w net.ipv4.ip_forward=1

nova secgroup-add-rule default tcp 1 65535 192.168.100.129/25
nova secgroup-add-rule default udp 1 65535 192.168.100.129/25
nova secgroup-add-rule default icmp -1 -1 192.168.100.129/25


nova secgroup-add-rule default tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule default udp 1 65535 0.0.0.0/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0


Users allow traffic to their instances using security groups. In our scenario,
 tenant1 and tenant2 could simply let their instances communicate by making the following adjustments in their security groups:
tenant1: nova secgroup-add-rule default tcp 1 65535 10.1.0.0/24
tenant2: nova secgroup-add-rule default tcp 1 65535 10.0.0.0/24
tenant1 lets TCP traffic on port range 1-65535 from tenant2?s net (10.1.0.0) and vice versa.
There are two scenarios, depending on where instances are put by OpenStack:
    Instances of both tenants reside on the same compute node.
    Instances of both tenants reside on different compute nodes.

