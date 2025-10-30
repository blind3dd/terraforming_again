#!/bin/bash

# Status Script - Shows current workspace and environment

echo "📊 Current Terraform Configuration Status"
echo "========================================"

# Show current workspace
CURRENT_WORKSPACE=$(terraform workspace show 2>/dev/null || echo "unknown")
echo "🏢 Current Workspace: $CURRENT_WORKSPACE"

# Show current environment (based on symlinks)
if [[ -L "main.tf" ]]; then
    CURRENT_ENV=$(readlink main.tf | sed 's|environments/||' | sed 's|/environment.tf||')
    echo "🌍 Current Environment: $CURRENT_ENV"
else
    echo "🌍 Current Environment: unknown (not using symlinks)"
fi

# Show current AWS account (if available)
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
echo "☁️  Current AWS Account: $CURRENT_ACCOUNT"

# Show current region (if available)
CURRENT_REGION=$(aws configure get region 2>/dev/null || echo "unknown")
echo "🌎 Current AWS Region: $CURRENT_REGION"

echo ""
echo "📋 Available Workspaces:"
terraform workspace list 2>/dev/null | sed 's/^/   /'

echo ""
echo "🔄 Quick Commands:"
echo "   # Switch workspace:"
echo "   terraform workspace select scalex-dc01-dev"
echo ""
echo "   # Switch environment:"
echo "   ./switch-environment.sh dev"
echo ""
echo "   # Deploy:"
echo "   terraform apply"
