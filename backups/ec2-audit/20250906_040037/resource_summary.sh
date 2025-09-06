#!/bin/bash
# Resource Summary Script

echo "=== EC2 Resource Summary ==="
echo "Date: $(date)"
echo

echo "VPCs:"
jq -r '.Vpcs | length' ec2/vpcs.json 2>/dev/null || echo "0"

echo "Subnets:"
jq -r '.Subnets | length' ec2/subnets.json 2>/dev/null || echo "0"

echo "Security Groups:"
jq -r '.SecurityGroups | length' ec2/security_groups.json 2>/dev/null || echo "0"

echo "Instances:"
jq -r '.Reservations[].Instances | length' ec2/instances.json 2>/dev/null || echo "0"

echo "Volumes:"
jq -r '.Volumes | length' ec2/volumes.json 2>/dev/null || echo "0"

echo "Snapshots:"
jq -r '.Snapshots | length' ec2/snapshots.json 2>/dev/null || echo "0"

echo "Internet Gateways:"
jq -r '.InternetGateways | length' ec2/internet_gateways.json 2>/dev/null || echo "0"

echo "NAT Gateways:"
jq -r '.NatGateways | length' ec2/nat_gateways.json 2>/dev/null || echo "0"
