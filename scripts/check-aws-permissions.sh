#!/bin/bash
# AWS Permissions Check Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Function to check AWS CLI
check_aws_cli() {
    log "Checking AWS CLI..."
    if command -v aws &> /dev/null; then
        success "AWS CLI is available"
        aws --version
    else
        error "AWS CLI is not installed"
        exit 1
    fi
}

# Function to check profile
check_profile() {
    local profile="$1"
    log "Checking profile: $profile"
    
    if aws sts get-caller-identity --profile "$profile" &> /dev/null; then
        success "Profile $profile is working"
        aws sts get-caller-identity --profile "$profile"
        return 0
    else
        error "Profile $profile is not working"
        return 1
    fi
}

# Function to test service permissions
test_service_permissions() {
    local profile="$1"
    local service="$2"
    local command="$3"
    local description="$4"
    
    log "Testing $description..."
    if eval "$command" &> /dev/null; then
        success "✅ $description: Access granted"
        return 0
    else
        warn "⚠️  $description: Access denied or no resources"
        return 1
    fi
}

# Function to check comprehensive permissions
check_permissions() {
    local profile="$1"
    log "Checking permissions for profile: $profile"
    
    # Basic services
    test_service_permissions "$profile" "ec2" "aws ec2 describe-regions --profile $profile" "EC2 Regions"
    test_service_permissions "$profile" "ec2" "aws ec2 describe-vpcs --profile $profile --max-items 1" "EC2 VPCs"
    test_service_permissions "$profile" "ecr" "aws ecr describe-repositories --profile $profile --max-items 1" "ECR Repositories"
    test_service_permissions "$profile" "rds" "aws rds describe-db-instances --profile $profile --max-items 1" "RDS Instances"
    test_service_permissions "$profile" "s3" "aws s3 ls --profile $profile" "S3 Buckets"
    
    # IAM and security
    test_service_permissions "$profile" "iam" "aws iam list-roles --profile $profile --max-items 1" "IAM Roles"
    test_service_permissions "$profile" "iam" "aws iam list-users --profile $profile --max-items 1" "IAM Users"
    test_service_permissions "$profile" "sts" "aws sts get-caller-identity --profile $profile" "STS Identity"
    
    # Networking
    test_service_permissions "$profile" "route53" "aws route53 list-hosted-zones --profile $profile --max-items 1" "Route53 Zones"
    test_service_permissions "$profile" "acm" "aws acm list-certificates --profile $profile --max-items 1" "ACM Certificates"
    
    # Monitoring and logging
    test_service_permissions "$profile" "logs" "aws logs describe-log-groups --profile $profile --max-items 1" "CloudWatch Logs"
    test_service_permissions "$profile" "cloudwatch" "aws cloudwatch list-metrics --profile $profile --namespace AWS/EC2 --max-items 1" "CloudWatch Metrics"
}

# Function to provide recommendations
provide_recommendations() {
    local profile="$1"
    log "📋 Recommendations for profile: $profile"
    
    echo ""
    echo "🚀 For Kubernetes Deployment, you need:"
    echo "   ✅ EC2: VPC, Subnets, Instances, Security Groups"
    echo "   ✅ ECR: Container Registry"
    echo "   ✅ RDS: Database"
    echo "   ✅ S3: Terraform State (optional but recommended)"
    echo "   ✅ IAM: Roles and Policies (for EC2 instances)"
    echo "   ✅ Route53: DNS (optional)"
    echo "   ✅ ACM: SSL Certificates (optional)"
    echo ""
    
    echo "🔐 IAM Permissions needed:"
    echo "   - iam:CreateRole"
    echo "   - iam:CreatePolicy"
    echo "   - iam:AttachRolePolicy"
    echo "   - iam:PassRole"
    echo ""
    
    echo "📝 Next steps:"
    if aws iam list-roles --profile "$profile" --max-items 1 &> /dev/null; then
        echo "   1. ✅ You can create IAM roles - proceed with role creation"
        echo "   2. Run: ansible-playbook create-assumable-role.yml -e 'trusted_principal=arn:aws:iam::$(aws sts get-caller-identity --profile $profile --query Account --output text):user/$(aws sts get-caller-identity --profile $profile --query UserId --output text)'"
    else
        echo "   1. ⚠️  You cannot create IAM roles with this profile"
        echo "   2. Use a different profile with IAM permissions"
        echo "   3. Or ask an admin to create the role for you"
        echo "   4. Or use existing credentials if you have them"
    fi
}

# Main execution
main() {
    log "🔍 AWS Permissions Check Script"
    log "This script will check your AWS permissions and provide recommendations"
    
    check_aws_cli
    
    # Check available profiles
    log "Checking available profiles..."
    profiles=("profile-test" "profile-iac")
    
    for profile in "${profiles[@]}"; do
        if check_profile "$profile"; then
            check_permissions "$profile"
            provide_recommendations "$profile"
            echo ""
            echo "=========================================="
            echo ""
        fi
    done
    
    success "✅ AWS permissions check completed!"
}

# Run main function
main "$@"
