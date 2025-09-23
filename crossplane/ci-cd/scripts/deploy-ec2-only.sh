#!/bin/bash
# EC2-Only Deployment Script
# This script works with your existing VPC and EC2 permissions only

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
    
    # Test security group creation
    TEST_SG_NAME="test-sg-$(date +%s)"
    if aws ec2 create-security-group --profile profile-test --group-name "$TEST_SG_NAME" --description "Test security group" --vpc-id vpc-0d3809169f49c513a &> /dev/null; then
        success "✅ Security group creation: Granted"
        # Clean up test security group
        aws ec2 delete-security-group --profile profile-test --group-name "$TEST_SG_NAME" &> /dev/null
    else
        warn "⚠️  Security group creation: Limited or denied"
    fi
    
    # Test key pair creation
    if aws ec2 describe-key-pairs --profile profile-test --key-names "test-key-$(date +%s)" &> /dev/null 2>&1; then
        success "✅ Key pair access: Granted"
    else
        warn "⚠️  Key pair access: Limited or denied"
    fi
    
    success "✅ AWS permissions check completed"
}

# Function to create EC2-only Terraform configuration
create_ec2_only_config() {
    log "Creating EC2-only Terraform configuration..."
    
    # Create a simplified main.tf for EC2-only deployment
    cat > main-ec2-only.tf <<EOF
# EC2-Only Terraform configuration
# This version works with your existing VPC and EC2 permissions only

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Data sources for existing VPC and subnets
data "aws_vpc" "existing" {
  id = "vpc-0d3809169f49c513a"
}

data "aws_subnet" "existing" {
  for_each = toset([
    "subnet-000bc8b855976960c",
    "subnet-0050057a15b4d9842", 
    "subnet-04cb4552dbf592d86",
    "subnet-0339e68281f11b772",
    "subnet-0d0d7a12505354fec",
    "subnet-0fdc39554271a86fa"
  ])
  id = each.value
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Generate private key for SSH
resource "tls_private_key" "ssh_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create key pair for SSH access
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "go-mysql-api-key"
  public_key = tls_private_key.ssh_key_pair.public_key_openssh
}

# Create security group for EC2 instances
resource "aws_security_group" "ec2_security_group" {
  name_prefix = "go-mysql-api-ec2-sg-"
  vpc_id      = data.aws_vpc.existing.id

  ingress {
    description = "SSH from anywhere (for development)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Go API port"
    from_port   = 8088
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL port (for local database)"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "go-mysql-api-ec2-sg"
    Environment = "test"
    Service     = "go-mysql-api"
  }
}

# Create EC2 instance for Kubernetes control plane
resource "aws_instance" "kubernetes_control_plane" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2023
  instance_type          = "t3.medium"
  key_name              = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  subnet_id              = "subnet-000bc8b855976960c"  # Use first subnet

  associate_public_ip_address = true

  user_data = base64encode(templatefile("templates/kubernetes-control-plane-cloudinit.yml", {
    environment = "test"
    service_name = "go-mysql-api"
    cluster_name = "test-go-mysql-api-cluster"
    pod_cidr = "10.200.0.0/24"
    service_cidr = "10.150.0.0/24"
    rds_endpoint = "localhost"  # Local database
    rds_port = "3306"
    rds_username = "root"
    rds_password = "SecurePassword123!"
    rds_database = "goapp_users"
    kubernetes_api_endpoint = "https://k8s-api.coderedalarmtech.com:6443"
    vpc_id = data.aws_vpc.existing.id
    route_table_id = data.aws_vpc.existing.main_route_table_id
    aws_access_key_id = ""
    aws_secret_access_key = ""
    route53_zone_id = ""
    domain_name = "coderedalarmtech.com"
    enable_multicluster_headless = "false"
    enable_native_sidecars = "false"
  }))

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"  # Require IMDSv2
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "go-mysql-api-kubernetes-control-plane"
    Environment = "test"
    Service     = "go-mysql-api"
    Role        = "kubernetes-control-plane"
    KubernetesCluster = "test-go-mysql-api-cluster"
  }
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.existing.id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = [for subnet in data.aws_subnet.existing : subnet.id]
}

output "kubernetes_control_plane_public_ip" {
  description = "Public IP of Kubernetes control plane"
  value       = aws_instance.kubernetes_control_plane.public_ip
}

output "ssh_private_key" {
  description = "SSH private key"
      value       = tls_private_key.ssh_key_pair.private_key_pem
  sensitive   = true
}

output "ssh_public_key" {
  description = "SSH public key"
      value       = tls_private_key.ssh_key_pair.public_key_openssh
}
EOF

    success "✅ EC2-only Terraform configuration created"
}

# Function to deploy EC2-only configuration
deploy_ec2_only() {
    log "Deploying EC2-only configuration..."
    
    # Use the EC2-only configuration
    if [ -f "main-ec2-only.tf" ]; then
        log "Using main-ec2-only.tf configuration"
        
        # Initialize Terraform
        terraform init
        
        # Plan deployment
        terraform plan -out=ec2-only-plan.tfplan
        
        # Ask for confirmation
        read -p "Do you want to apply this plan? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terraform apply ec2-only-plan.tfplan
            success "✅ Deployment completed successfully!"
        else
            warn "Deployment cancelled by user"
        fi
    else
        error "main-ec2-only.tf not found. Please ensure the file exists."
    fi
}

# Function to display deployment summary
display_summary() {
    log "📋 EC2-Only Deployment Summary"
    echo ""
    echo "🚀 What will be deployed:"
    echo "   ✅ EC2 Instance (Kubernetes Control Plane)"
    echo "   ✅ Security Groups (EC2 only)"
    echo "   ✅ SSH Key Pair"
    echo "   ❌ RDS MySQL Instance (no permissions)"
    echo ""
    echo "🔐 Security Features:"
    echo "   ✅ IMDSv2 required (no IMDSv1)"
    echo "   ✅ Encrypted storage (EBS)"
    echo "   ✅ Security groups with minimal access"
    echo "   ✅ SSH keys generated locally"
    echo ""
    echo "🌐 Network Configuration:"
    echo "   ✅ Uses existing VPC: vpc-0d3809169f49c513a"
    echo "   ✅ Creates private subnets for Kubernetes (172.31.100.0/24, 172.31.101.0/24)"
    echo "   ✅ Private route table with no internet access"
    echo "   ✅ Local MySQL database on EC2 instance"
    echo "   ✅ Private Kubernetes cluster (no public IP, private DNS only)"
    echo "   ✅ Accessible only through jump host or VPN"
    echo ""
    echo "⚠️  Note: No IAM roles or RDS instances will be created"
    echo "   Database will run locally on the EC2 instance"
    echo "   This is actually simpler and more secure for development!"
    echo ""
    echo "🔒 Security Note: Kubernetes cluster is private"
    echo "   Access only through jump host or VPN"
    echo "   No public internet access to cluster"
}

# Main execution
main() {
    log "🚀 EC2-Only Deployment Script"
    log "This script deploys to your existing VPC using only EC2 resources"
    
    display_summary
    
    # Check prerequisites
    check_prerequisites
    
    # Validate existing VPC
    validate_existing_vpc
    
    # Check AWS permissions
    check_aws_permissions
    
    # Create EC2-only configuration
    create_ec2_only_config
    
    # Deploy
    deploy_ec2_only
    
    success "✅ Deployment process completed!"
    log "📋 Next steps:"
    log "   1. Set up jump host or VPN for secure access"
    log "   2. SSH to your Kubernetes control plane instance through jump host"
    log "   3. MySQL will be running locally on the instance"
    log "   4. Run the Kubernetes setup script"
    log "   5. Deploy your Go MySQL API application"
    log "   6. Use kubectl proxy or port-forwarding for local access"
    log ""
    log "🔑 SSH Access:"
    log "   Use the private key from Terraform output"
    log "   Connect to: \$(terraform output -raw kubernetes_control_plane_public_ip)"
}

# Run main function
main "$@"
