#!/bin/bash

# Quick GitHub Actions Workflow Testing
# Simple script to test workflows without complex setup

set -euo pipefail

echo "🚀 Quick GitHub Actions Workflow Test"
echo "====================================="

# Test 1: Validate YAML syntax
echo "📋 Testing YAML syntax..."
python3 -c "
import yaml
import sys
import glob

failed = False
for workflow in glob.glob('.github/workflows/*.yml'):
    try:
        with open(workflow, 'r') as f:
            yaml.safe_load(f)
        print(f'  ✅ {workflow}')
    except yaml.YAMLError as e:
        print(f'  ❌ {workflow}: {e}')
        failed = True

if failed:
    sys.exit(1)
else:
    print('✅ All workflows have valid YAML syntax')
"

# Test 2: Check for common issues
echo -e "\n🔍 Checking for common issues..."

# Check for workflow_dispatch in manual workflows
echo "  Checking manual triggers..."
for workflow in .github/workflows/*.yml; do
    if [[ -f "$workflow" ]]; then
        if grep -q "workflow_dispatch:" "$workflow"; then
            echo "    ✅ $(basename "$workflow") has manual trigger"
        fi
    fi
done

# Check for required secrets
echo "  Checking environment..."
if [[ -n "${AWS_ACCESS_KEY_ID:-}" ]]; then
    echo "    ✅ AWS_ACCESS_KEY_ID is set"
else
    echo "    ⚠️  AWS_ACCESS_KEY_ID is not set"
fi

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    echo "    ✅ GITHUB_TOKEN is set"
else
    echo "    ⚠️  GITHUB_TOKEN is not set"
fi

echo -e "\n🎉 Quick test completed!"
echo "For comprehensive testing, run: ./scripts/test-all-workflows.sh"
