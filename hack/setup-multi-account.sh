#!/bin/bash

# Multi-Account Workspace Setup Script
# Usage: ./setup-multi-account.sh [environment] [account-id]

set -e

ENVIRONMENT=${1:-shared}
ACCOUNT_ID=${2:-$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")}

if [[ ! "$ENVIRONMENT" =~ ^(shared|dev|test|sandbox)$ ]]; then
    echo "❌ Invalid environment. Use: shared, dev, test, or sandbox"
    echo "Usage: $0 [environment] [account-id]"
    exit 1
fi

if [[ "$ACCOUNT_ID" == "unknown" ]]; then
    echo "❌ Could not determine AWS account ID"
    echo "Please provide account ID: $0 $ENVIRONMENT 123456789012"
    exit 1
fi

echo "🔄 Setting up workspaces for $ENVIRONMENT environment in account $ACCOUNT_ID..."

# Switch to the environment first
./switch-environment.sh $ENVIRONMENT

# Create account-specific workspace names
WORKSPACE_PREFIX="${ENVIRONMENT}-${ACCOUNT_ID}"

echo "📋 Creating workspaces with prefix: $WORKSPACE_PREFIX"

# Create account-specific workspaces
terraform workspace new ${WORKSPACE_PREFIX}-backend 2>/dev/null || echo "Workspace ${WORKSPACE_PREFIX}-backend already exists"
terraform workspace new ${WORKSPACE_PREFIX}-infrastructure 2>/dev/null || echo "Workspace ${WORKSPACE_PREFIX}-infrastructure already exists"
terraform workspace new ${WORKSPACE_PREFIX}-main 2>/dev/null || echo "Workspace ${WORKSPACE_PREFIX}-main already exists"

echo "✅ Workspaces created for $ENVIRONMENT environment in account $ACCOUNT_ID:"
echo "   - ${WORKSPACE_PREFIX}-main (default)"
echo "   - ${WORKSPACE_PREFIX}-backend (for backend infrastructure)"
echo "   - ${WORKSPACE_PREFIX}-infrastructure (for main infrastructure)"

echo ""
echo "🚀 Usage:"
echo "   # Switch to backend workspace"
echo "   terraform workspace select ${WORKSPACE_PREFIX}-backend"
echo "   terraform apply -var='create_backend=true' -var='state_bucket_name=terraform-state-bucket-${ACCOUNT_ID}'"
echo ""
echo "   # Switch to infrastructure workspace"
echo "   terraform workspace select ${WORKSPACE_PREFIX}-infrastructure"
echo "   terraform apply -var='create_backend=false'"
echo ""
echo "   # List all workspaces for this account"
echo "   terraform workspace list | grep $ACCOUNT_ID"
echo ""
echo "   # Switch between accounts"
echo "   terraform workspace select ${ENVIRONMENT}-123456789-backend"
echo "   terraform workspace select ${ENVIRONMENT}-987654321-backend"
