#!/bin/bash

# Switch Environment Script
# Usage: ./switch-environment.sh [shared|dev|test|sandbox]

set -e

ENVIRONMENT=${1:-shared}

if [[ ! "$ENVIRONMENT" =~ ^(shared|dev|test|sandbox)$ ]]; then
    echo "❌ Invalid environment. Use: shared, dev, test, or sandbox"
    echo "Usage: $0 [shared|dev|test|sandbox]"
    exit 1
fi

echo "🔄 Switching to $ENVIRONMENT environment..."

# Remove existing symlinks
rm -f main.tf variables.tf

# Create new symlinks
ln -sf "environments/$ENVIRONMENT/environment.tf" main.tf
ln -sf "environments/$ENVIRONMENT/variables.tf" variables.tf

echo "✅ Switched to $ENVIRONMENT environment"
echo "📁 Current configuration:"
echo "   - main.tf -> environments/$ENVIRONMENT/environment.tf"
echo "   - variables.tf -> environments/$ENVIRONMENT/variables.tf"
echo ""
echo "🚀 You can now run:"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
