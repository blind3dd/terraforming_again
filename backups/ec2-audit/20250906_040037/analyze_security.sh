#!/bin/bash
# Security Analysis Script

echo "=== EC2 Security Analysis ==="
echo "Date: $(date)"
echo

echo "Security Groups with Open Access:"
jq -r '.SecurityGroups[] | select(.IpPermissions[]?.IpRanges[]?.CidrIp == "0.0.0.0/0") | "\(.GroupId): \(.GroupName)"' ec2/security_groups.json 2>/dev/null || echo "No overly permissive security groups"

echo
echo "Instances with Public IPs:"
jq -r '.Reservations[].Instances[] | select(.PublicIpAddress != null) | "\(.InstanceId): \(.PublicIpAddress)"' ec2/instances.json 2>/dev/null || echo "No instances with public IPs"

echo
echo "Default VPC Usage:"
jq -r '.Vpcs[] | select(.IsDefault == true) | "\(.VpcId): \(.CidrBlock)"' ec2/vpcs.json 2>/dev/null || echo "No default VPC found"

echo
echo "Detached Internet Gateways:"
jq -r '.InternetGateways[] | select(.Attachments | length == 0) | .InternetGatewayId' ec2/internet_gateways.json 2>/dev/null || echo "No detached internet gateways"
