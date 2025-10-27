#!/bin/bash

# Terraform Workspace Setup Script
# This creates workspaces for additional state isolation within each environment

set -e

ENVIRONMENT=${1:-shared}

if [[ ! "$ENVIRONMENT" =~ ^(shared|dev|test|sandbox)$ ]]; then
    echo "❌ Invalid environment. Use: shared, dev, test, or sandbox"
    echo "Usage: $0 [shared|dev|test|sandbox]"
    exit 1
fi

echo "🔄 Setting up workspaces for $ENVIRONMENT environment..."

# Switch to the environment first
./switch-environment.sh $ENVIRONMENT

# Create workspaces if they don't exist
echo "📋 Creating workspaces..."

# Create environment-specific workspaces
terraform workspace new ${ENVIRONMENT}-main 2>/dev/null || echo "Workspace ${ENVIRONMENT}-main already exists"
terraform workspace new ${ENVIRONMENT}-backend 2>/dev/null || echo "Workspace ${ENVIRONMENT}-backend already exists"
terraform workspace new ${ENVIRONMENT}-infrastructure 2>/dev/null || echo "Workspace ${ENVIRONMENT}-infrastructure already exists"

echo "✅ Workspaces created for $ENVIRONMENT environment:"
echo "   - ${ENVIRONMENT}-main (default)"
echo "   - ${ENVIRONMENT}-backend (for backend infrastructure)"
echo "   - ${ENVIRONMENT}-infrastructure (for main infrastructure)"

echo ""
echo "🚀 Usage:"
echo "   # Switch to backend workspace"
echo "   terraform workspace select ${ENVIRONMENT}-backend"
echo "   terraform apply -var='create_backend=true'"
echo ""
echo "   # Switch to infrastructure workspace"
echo "   terraform workspace select ${ENVIRONMENT}-infrastructure"
echo "   terraform apply -var='create_backend=false'"
echo ""
echo "   # List all workspaces"
echo "   terraform workspace list"
