#!/bin/bash
# Update Terraform Variables Script

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

# Function to backup current terraform.tfvars
backup_tfvars() {
    if [ -f "terraform.tfvars" ]; then
        cp terraform.tfvars "terraform.tfvars.backup.$(date +%Y%m%d-%H%M%S)"
        success "Backed up terraform.tfvars"
    fi
}

# Function to update terraform.tfvars
update_tfvars() {
    log "Updating terraform.tfvars..."
    
    # Get current values or set defaults
    current_region=$(grep '^region =' terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "us-east-1")
    current_environment=$(grep '^environment =' terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "test")
    current_service_name=$(grep '^service_name =' terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "go-mysql-api")
    
    # Get AWS credentials from user
    read -p "Enter AWS Access Key ID: " aws_access_key_id
    read -s -p "Enter AWS Secret Access Key: " aws_secret_access_key
    echo
    read -p "Enter AWS Region (current: $current_region): " aws_region
    aws_region=${aws_region:-$current_region}
    
    # Get Route53 and domain information
    read -p "Enter Route53 Zone ID (optional): " route53_zone_id
    read -p "Enter Domain Name (optional, current: $current_service_name.example.com): " domain_name
    domain_name=${domain_name:-"$current_service_name.example.com"}
    
    # Update terraform.tfvars
    cat > terraform.tfvars <<EOF
# AWS Configuration
region = "$aws_region"
environment = "$current_environment"
service_name = "$current_service_name"

# VPC Configuration
main_vpc_cidr = "10.0.0.0/16"
private_subnet_range_a = "10.0.1.0/24"
private_subnet_range_b = "10.0.2.0/24"
public_subnet_range = "10.0.3.0/24"

# Instance Configuration
instance_type = "t3.medium"
instance_ami = "ami-0c02fb55956c7d316"  # Amazon Linux 2023 in us-east-1
instance_os = "Amazon Linux 2023"
associate_public_ip_address = true

# Database Configuration
db_name = "mock_user"
db_username = "db_user"
db_password = "SecurePassword123!"
db_instance_class = "db.t3.micro"
db_engine_version = "8.0.35"

# Key Pair Configuration
aws_key_pair_name = "go-mysql-api-key"
key_algorithm = "RSA"
key_bits_size = 4096

# Infrastructure Configuration
infra_builder = "terraform"
db_password_param = "/$current_environment/$current_service_name/db/password"

# AWS Credentials
aws_access_key_id = "$aws_access_key_id"
aws_secret_access_key = "$aws_secret_access_key"
route53_zone_id = "$route53_zone_id"
domain_name = "$domain_name"
EOF
    
    success "Updated terraform.tfvars with your credentials"
}

# Function to validate the updated file
validate_tfvars() {
    log "Validating terraform.tfvars..."
    
    if [ -f "terraform.tfvars" ]; then
        # Check if required fields are present
        if grep -q "aws_access_key_id = \"\"" terraform.tfvars; then
            warn "AWS Access Key ID is empty"
        fi
        if grep -q "aws_secret_access_key = \"\"" terraform.tfvars; then
            warn "AWS Secret Access Key is empty"
        fi
        
        success "terraform.tfvars validation completed"
        echo ""
        echo "Current configuration:"
        echo "Region: $(grep '^region =' terraform.tfvars | cut -d'"' -f2)"
        echo "Environment: $(grep '^environment =' terraform.tfvars | cut -d'"' -f2)"
        echo "Service: $(grep '^service_name =' terraform.tfvars | cut -d'"' -f2)"
        echo "Domain: $(grep '^domain_name =' terraform.tfvars | cut -d'"' -f2)"
    else
        error "terraform.tfvars file not found"
    fi
}

# Main execution
main() {
    log "🔧 Terraform Variables Update Script"
    log "This script will help you update terraform.tfvars with your AWS credentials"
    
    backup_tfvars
    update_tfvars
    validate_tfvars
    
    success "✅ Terraform variables updated successfully!"
    log "📋 Next steps:"
    log "   1. Review terraform.tfvars to ensure all values are correct"
    log "   2. Run: ./deploy-kubernetes-control-plane.sh"
    log "   3. Or run manually: terraform init && terraform plan && terraform apply"
}

# Run main function
main "$@"
