#!/bin/bash

# Workspace Setup Script for Multi-Account/Datacenter
# Creates workspaces like: scalex-dc01-dev, scalex-dc02-test, etc.

set -e

echo "🚀 Setting up Terraform workspaces for multi-account/datacenter setup..."

# Create workspaces for different accounts/datacenters
echo "📋 Creating workspaces..."

# Example workspaces - customize these for your actual accounts/datacenters
terraform workspace new scalex-dc01-dev 2>/dev/null || echo "Workspace scalex-dc01-dev already exists"
terraform workspace new scalex-dc01-test 2>/dev/null || echo "Workspace scalex-dc01-test already exists"
terraform workspace new scalex-dc01-sandbox 2>/dev/null || echo "Workspace scalex-dc01-sandbox already exists"

terraform workspace new scalex-dc02-dev 2>/dev/null || echo "Workspace scalex-dc02-dev already exists"
terraform workspace new scalex-dc02-test 2>/dev/null || echo "Workspace scalex-dc02-test already exists"
terraform workspace new scalex-dc02-sandbox 2>/dev/null || echo "Workspace scalex-dc02-sandbox already exists"

# Add more accounts/datacenters as needed
# terraform workspace new scalex-dc03-dev 2>/dev/null || echo "Workspace scalex-dc03-dev already exists"
# terraform workspace new scalex-dc03-test 2>/dev/null || echo "Workspace scalex-dc03-test already exists"

echo "✅ Workspaces created:"
echo "   - scalex-dc01-dev"
echo "   - scalex-dc01-test"
echo "   - scalex-dc01-sandbox"
echo "   - scalex-dc02-dev"
echo "   - scalex-dc02-test"
echo "   - scalex-dc02-sandbox"

echo ""
echo "🚀 Usage:"
echo "   # 1. Select workspace (account/datacenter + environment)"
echo "   terraform workspace select scalex-dc01-dev"
echo ""
echo "   # 2. Switch to environment configuration"
echo "   ./switch-environment.sh dev"
echo ""
echo "   # 3. Deploy infrastructure"
echo "   terraform apply"
echo ""
echo "   # Example workflow:"
echo "   terraform workspace select scalex-dc01-dev"
echo "   ./switch-environment.sh dev"
echo "   terraform apply -var='create_backend=true'"
echo ""
echo "   # Switch to different account/datacenter:"
echo "   terraform workspace select scalex-dc02-test"
echo "   ./switch-environment.sh test"
echo "   terraform apply"
echo ""
echo "📋 List all workspaces:"
echo "   terraform workspace list"
