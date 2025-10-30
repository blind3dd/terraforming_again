#!/bin/bash
set -e

echo "🔧 Updating iacrole Trust Policy"
echo "================================="
echo ""

ROLE_NAME="iacrole"
TRUST_POLICY_FILE="hack/iacrole-trust-policy-updated.json"

echo "📋 Current trust policy location: ${TRUST_POLICY_FILE}"
echo ""

echo "🔄 Updating IAM role trust policy..."
aws iam update-assume-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-document file://${TRUST_POLICY_FILE}

echo ""
echo "✅ Trust policy updated successfully!"
echo ""
echo "🔍 Verify the update:"
echo "aws iam get-role --role-name ${ROLE_NAME} --query 'Role.AssumeRolePolicyDocument'"
echo ""

