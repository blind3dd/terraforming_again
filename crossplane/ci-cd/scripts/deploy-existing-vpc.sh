#!/bin/bash
# Deploy to Existing VPC Script
# This script works with your existing VPC and doesn't require IAM role creation

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
    exit 1
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install AWS CLI first."
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed. Please install Terraform first."
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity --profile profile-test &> /dev/null; then
        error "AWS credentials are not configured for profile-test. Please check your AWS configuration."
    fi
    
    success "✅ Prerequisites check completed"
}

# Function to validate existing VPC
validate_existing_vpc() {
    log "Validating existing VPC configuration..."
    
    # Check if VPC exists
    VPC_ID="vpc-0d3809169f49c513a"
    if ! aws ec2 describe-vpcs --profile profile-test --vpc-ids "$VPC_ID" &> /dev/null; then
        error "VPC $VPC_ID not found or not accessible"
    fi
    
    # Check if subnets exist
    SUBNET_IDS=("subnet-000bc8b855976960c" "subnet-0050057a15b4d9842" "subnet-04cb4552dbf592d86" "subnet-0339e68281f11b772" "subnet-0d0d7a12505354fec" "subnet-0fdc39554271a86fa")
    
    for subnet_id in "${SUBNET_IDS[@]}"; do
        if ! aws ec2 describe-subnets --profile profile-test --subnet-ids "$subnet_id" &> /dev/null; then
            error "Subnet $subnet_id not found or not accessible"
        fi
    done
    
    success "✅ Existing VPC validation completed"
    log "VPC ID: $VPC_ID"
    log "Subnet IDs: ${SUBNET_IDS[*]}"
}

# Function to check AWS permissions
check_aws_permissions() {
    log "Checking AWS permissions..."
    
    # Test EC2 permissions
    if aws ec2 describe-regions --profile profile-test &> /dev/null; then
        success "✅ EC2 access: Granted"
    else
        error "❌ EC2 access: Denied"
    fi
    
    # Test RDS permissions
    if aws rds describe-db-instances --profile profile-test &> /dev/null; then
        success "✅ RDS access: Granted"
    else
        error "❌ RDS access: Denied"
    fi
    
    # Test security group creation
    TEST_SG_NAME="test-sg-$(date +%s)"
    if aws ec2 create-security-group --profile profile-test --group-name "$TEST_SG_NAME" --description "Test security group" --vpc-id vpc-0d3809169f49c513a &> /dev/null; then
        success "✅ Security group creation: Granted"
        # Clean up test security group
        aws ec2 delete-security-group --profile profile-test --group-name "$TEST_SG_NAME" &> /dev/null
    else
        warn "⚠️  Security group creation: Limited or denied"
    fi
    
    success "✅ AWS permissions check completed"
}

# Function to update terraform.tfvars with existing VPC
update_terraform_vars() {
    log "Updating terraform.tfvars with existing VPC configuration..."
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        error "terraform.tfvars not found"
    fi
    
    # Update the file with existing VPC info
    sed -i.bak 's/main_vpc_cidr = "10.0.0.0\/16"/main_vpc_cidr = "172.31.0.0\/16"/' terraform.tfvars
    sed -i.bak 's/private_subnet_range_a = "10.0.1.0\/24"/private_subnet_range_a = "172.31.16.0\/20"/' terraform.tfvars
    sed -i.bak 's/private_subnet_range_b = "10.0.2.0\/24"/private_subnet_range_b = "172.31.32.0\/20"/' terraform.tfvars
    sed -i.bak 's/public_subnet_range = "10.0.3.0\/24"/public_subnet_range = "172.31.48.0\/20"/' terraform.tfvars
    
    success "✅ terraform.tfvars updated with existing VPC configuration"
}

# Function to deploy with existing VPC configuration
deploy_existing_vpc() {
    log "Deploying with existing VPC configuration..."
    
    # Use the existing VPC configuration
    if [ -f "main-existing-vpc.tf" ]; then
        log "Using main-existing-vpc.tf configuration"
        
        # Initialize Terraform
        terraform init
        
        # Plan deployment
        terraform plan -out=existing-vpc-plan.tfplan
        
        # Ask for confirmation
        read -p "Do you want to apply this plan? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terraform apply existing-vpc-plan.tfplan
            success "✅ Deployment completed successfully!"
        else
            warn "Deployment cancelled by user"
        fi
    else
        error "main-existing-vpc.tf not found. Please ensure the file exists."
    fi
}

# Function to display deployment summary
display_summary() {
    log "📋 Deployment Summary"
    echo ""
    echo "🚀 What will be deployed:"
    echo "   ✅ EC2 Instance (Kubernetes Control Plane)"
    echo "   ✅ RDS MySQL Instance"
    echo "   ✅ Security Groups (EC2 and RDS)"
    echo "   ✅ SSH Key Pair"
    echo "   ✅ SSM Parameters (SSH keys, DB password)"
    echo ""
    echo "🔐 Security Features:"
    echo "   ✅ IMDSv2 required (no IMDSv1)"
    echo "   ✅ Encrypted storage (EBS and RDS)"
    echo "   ✅ Security groups with minimal access"
    echo "   ✅ SSH keys stored in SSM Parameter Store"
    echo ""
    echo "🌐 Network Configuration:"
    echo "   ✅ Uses existing VPC: vpc-0d3809169f49c513a"
    echo "   ✅ Uses existing subnets across 6 AZs"
    echo "   ✅ Private RDS with EC2-only access"
    echo ""
    echo "⚠️  Note: No IAM roles will be created (you don't have permissions)"
    echo "   This is actually more secure for your use case!"
}

# Main execution
main() {
    log "🚀 Existing VPC Deployment Script"
    log "This script deploys to your existing VPC without requiring IAM permissions"
    
    display_summary
    
    # Check prerequisites
    check_prerequisites
    
    # Validate existing VPC
    validate_existing_vpc
    
    # Check AWS permissions
    check_aws_permissions
    
    # Update terraform.tfvars
    update_terraform_vars
    
    # Deploy
    deploy_existing_vpc
    
    success "✅ Deployment process completed!"
    log "📋 Next steps:"
    log "   1. SSH to your Kubernetes control plane instance"
    log "   2. Run the Kubernetes setup script"
    log "   3. Join worker nodes to the cluster"
    log "   4. Deploy your Go MySQL API application"
}

# Run main function
main "$@"
