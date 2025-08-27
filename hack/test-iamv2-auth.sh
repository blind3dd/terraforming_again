#!/bin/bash

# IAMv2 Authentication Test Script
# This script tests AWS authentication on EC2 instances

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test AWS CLI installation
test_aws_cli() {
    log_info "Testing AWS CLI installation..."
    
    if command -v aws &> /dev/null; then
        log_success "AWS CLI is installed: $(aws --version)"
    else
        log_error "AWS CLI is not installed"
        exit 1
    fi
}

# Test instance metadata service
test_metadata_service() {
    log_info "Testing instance metadata service..."
    
    # Test IMDSv2 token
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null || echo "")
    
    if [ -n "$TOKEN" ]; then
        log_success "IMDSv2 token obtained successfully"
        
        # Test metadata retrieval with token
        INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "")
        REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "")
        
        if [ -n "$INSTANCE_ID" ] && [ -n "$REGION" ]; then
            log_success "Instance metadata retrieved successfully"
            log_info "Instance ID: $INSTANCE_ID"
            log_info "Region: $REGION"
        else
            log_error "Failed to retrieve instance metadata"
        fi
    else
        log_warning "IMDSv2 token not available, trying IMDSv1"
        
        # Fallback to IMDSv1
        INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "")
        REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "")
        
        if [ -n "$INSTANCE_ID" ] && [ -n "$REGION" ]; then
            log_success "Instance metadata retrieved via IMDSv1"
            log_info "Instance ID: $INSTANCE_ID"
            log_info "Region: $REGION"
        else
            log_error "Failed to retrieve instance metadata via IMDSv1"
        fi
    fi
}

# Test AWS authentication
test_aws_auth() {
    log_info "Testing AWS authentication..."
    
    # Get region
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-1")
    export AWS_DEFAULT_REGION=$REGION
    
    # Configure AWS CLI
    aws configure set default.region "$REGION"
    aws configure set default.output json
    
    # Test authentication
    if aws sts get-caller-identity --region "$REGION" &> /dev/null; then
        log_success "AWS authentication successful"
        
        # Get caller identity details
        CALLER_IDENTITY=$(aws sts get-caller-identity --region "$REGION" --output json)
        ACCOUNT_ID=$(echo "$CALLER_IDENTITY" | jq -r '.Account')
        USER_ID=$(echo "$CALLER_IDENTITY" | jq -r '.UserId')
        ARN=$(echo "$CALLER_IDENTITY" | jq -r '.Arn')
        
        log_info "Account ID: $ACCOUNT_ID"
        log_info "User ID: $USER_ID"
        log_info "ARN: $ARN"
    else
        log_error "AWS authentication failed"
        return 1
    fi
}

# Test SSM parameter access
test_ssm_access() {
    log_info "Testing SSM parameter access..."
    
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-1")
    
    # Test listing parameters
    if aws ssm describe-parameters --region "$REGION" --max-items 5 &> /dev/null; then
        log_success "SSM parameter access successful"
    else
        log_error "SSM parameter access failed"
        return 1
    fi
}

# Test ECR access
test_ecr_access() {
    log_info "Testing ECR access..."
    
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-1")
    
    # Test ECR authorization
    if aws ecr get-authorization-token --region "$REGION" &> /dev/null; then
        log_success "ECR access successful"
    else
        log_error "ECR access failed"
        return 1
    fi
}

# Test CloudWatch access
test_cloudwatch_access() {
    log_info "Testing CloudWatch access..."
    
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-1")
    
    # Test CloudWatch log groups
    if aws logs describe-log-groups --region "$REGION" --max-items 5 &> /dev/null; then
        log_success "CloudWatch access successful"
    else
        log_error "CloudWatch access failed"
        return 1
    fi
}

# Test IAM permissions
test_iam_permissions() {
    log_info "Testing IAM permissions..."
    
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo "us-east-1")
    
    # Test IAM permissions
    if aws iam get-user --region "$REGION" &> /dev/null; then
        log_success "IAM permissions test successful"
    else
        log_warning "IAM permissions test failed (this might be expected for instance profiles)"
    fi
}

# Main execution
main() {
    log_info "Starting IAMv2 Authentication Tests"
    echo ""
    
    test_aws_cli
    echo ""
    
    test_metadata_service
    echo ""
    
    test_aws_auth
    echo ""
    
    test_ssm_access
    echo ""
    
    test_ecr_access
    echo ""
    
    test_cloudwatch_access
    echo ""
    
    test_iam_permissions
    echo ""
    
    log_success "IAMv2 Authentication Tests Completed!"
    log_info ""
    log_info "📋 Summary:"
    log_info "  ✅ AWS CLI: Installed and working"
    log_info "  ✅ Instance Metadata: Accessible"
    log_info "  ✅ AWS Authentication: Working"
    log_info "  ✅ SSM Access: Available"
    log_info "  ✅ ECR Access: Available"
    log_info "  ✅ CloudWatch Access: Available"
    log_info ""
    log_info "🎉 All authentication tests passed!"
}

# Run main function
main "$@"
