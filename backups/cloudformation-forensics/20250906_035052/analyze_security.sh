#!/bin/bash
# Security Analysis Script

echo "=== Security Analysis ==="
echo "Date: $(date)"
echo

echo "Security Groups with Open Access:"
jq -r '.SecurityGroups[] | select(.IpPermissions[]?.IpRanges[]?.CidrIp == "0.0.0.0/0") | "\(.GroupId): \(.GroupName)"' resources/security_groups.json 2>/dev/null || echo "No data"

echo
echo "Instances with Public IPs:"
jq -r '.Reservations[].Instances[] | select(.PublicIpAddress != null) | "\(.InstanceId): \(.PublicIpAddress)"' resources/instances.json 2>/dev/null || echo "No data"

echo
echo "IAM Roles:"
jq -r '.Roles[] | "\(.RoleName): \(.AssumeRolePolicyDocument)"' resources/iam_roles.json 2>/dev/null || echo "No data"
