#!/bin/bash

# Setup AWS Cost Check Script
# This script helps you configure AWS CLI and then run cost checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status $BLUE "🔧 AWS Cost Check Setup"
echo

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_status $RED "❌ AWS CLI is not installed"
    print_status $YELLOW "Please install AWS CLI first:"
    print_status $YELLOW "  - Nix: nix-env -iA nixpkgs.awscli2"
    print_status $YELLOW "  - Linux: sudo apt-get install awscli"
    print_status $YELLOW "  - Or download from: https://aws.amazon.com/cli/"
    exit 1
fi

print_status $GREEN "✅ AWS CLI is installed"

# Check if AWS CLI is configured
if aws sts get-caller-identity &> /dev/null; then
    account_id=$(aws sts get-caller-identity --query Account --output text)
    user_arn=$(aws sts get-caller-identity --query Arn --output text)
    print_status $GREEN "✅ AWS CLI is already configured"
    print_status $BLUE "👤 Account: $account_id"
    print_status $BLUE "👤 User: $user_arn"
    echo
    
    # Ask if user wants to run cost check
    read -p "Do you want to run the cost check now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status $BLUE "🔍 Running cost check..."
        ./aws-quick-cost-check.sh
    else
        print_status $YELLOW "You can run the cost check later with: ./aws-quick-cost-check.sh"
    fi
else
    print_status $YELLOW "⚠️  AWS CLI is not configured"
    echo
    print_status $BLUE "To configure AWS CLI, you need:"
    print_status $BLUE "  1. AWS Access Key ID"
    print_status $BLUE "  2. AWS Secret Access Key"
    print_status $BLUE "  3. Default region (e.g., us-east-1)"
    print_status $BLUE "  4. Default output format (e.g., json)"
    echo
    
    print_status $YELLOW "You can get these from:"
    print_status $YELLOW "  - AWS Console → IAM → Users → Your User → Security Credentials"
    print_status $YELLOW "  - Or use AWS SSO if your organization uses it"
    echo
    
    read -p "Do you want to configure AWS CLI now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status $BLUE "🔧 Running AWS CLI configuration..."
        aws configure
        echo
        
        # Test the configuration
        if aws sts get-caller-identity &> /dev/null; then
            account_id=$(aws sts get-caller-identity --query Account --output text)
            print_status $GREEN "✅ AWS CLI configured successfully!"
            print_status $BLUE "👤 Account: $account_id"
            echo
            
            # Ask if user wants to run cost check
            read -p "Do you want to run the cost check now? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_status $BLUE "🔍 Running cost check..."
                ./aws-quick-cost-check.sh
            else
                print_status $YELLOW "You can run the cost check later with: ./aws-quick-cost-check.sh"
            fi
        else
            print_status $RED "❌ AWS CLI configuration failed. Please try again."
        fi
    else
        print_status $YELLOW "You can configure AWS CLI later with: aws configure"
        print_status $YELLOW "Then run the cost check with: ./aws-quick-cost-check.sh"
    fi
fi

echo
print_status $GREEN "📋 Available scripts:"
print_status $GREEN "  - ./aws-quick-cost-check.sh    (Quick check of expensive resources)"
print_status $GREEN "  - ./aws-cost-audit.sh         (Comprehensive audit of all resources)"
print_status $GREEN "  - ./setup-aws-cost-check.sh   (This setup script)"
