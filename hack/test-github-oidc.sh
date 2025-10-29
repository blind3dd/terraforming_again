#!/bin/bash
set -e

echo "🔍 Testing GitHub OIDC Configuration"
echo "====================================="
echo ""

ROLE_ARN="arn:aws:iam::690248313240:role/iacrole"
ACCOUNT_ID="690248313240"

echo "📋 Step 1: Verify OIDC Provider exists"
echo "--------------------------------------"
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com" \
  2>/dev/null && echo "✅ OIDC Provider exists" || echo "❌ OIDC Provider NOT found"

echo ""
echo "📋 Step 2: Verify IAM Role exists"
echo "---------------------------------"
aws iam get-role --role-name iacrole \
  --query 'Role.RoleName' \
  --output text 2>/dev/null && echo "✅ IAM Role exists" || echo "❌ IAM Role NOT found"

echo ""
echo "📋 Step 3: Check Trust Policy"
echo "-----------------------------"
aws iam get-role --role-name iacrole \
  --query 'Role.AssumeRolePolicyDocument' \
  --output json

echo ""
echo "📋 Step 4: Check Role Permissions"
echo "---------------------------------"
echo "Attached Policies:"
aws iam list-attached-role-policies --role-name iacrole \
  --query 'AttachedPolicies[*].[PolicyName,PolicyArn]' \
  --output table

echo ""
echo "Inline Policies:"
aws iam list-role-policies --role-name iacrole \
  --query 'PolicyNames' \
  --output table

echo ""
echo "✅ Configuration Check Complete"
echo ""
echo "🎯 GitHub Secret should be:"
echo "   Name: AWS_ROLE_TO_ASSUME"
echo "   Value: ${ROLE_ARN}"
echo ""

