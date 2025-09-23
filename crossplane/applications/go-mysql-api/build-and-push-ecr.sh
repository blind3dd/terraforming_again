#!/bin/bash

# Build and Push Go MySQL API to ECR
# This script builds the Docker image and pushes it to AWS ECR

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="go-mysql-api"
DEFAULT_TAG="latest"
TAG="${1:-$DEFAULT_TAG}"
ENVIRONMENT="${ENVIRONMENT:-sandbox}"
SERVICE_NAME="${SERVICE_NAME:-go-mysql-api}"

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

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    log_success "AWS CLI found"
}

# Check if Docker is installed and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    log_success "Docker is running"
}

# Get ECR repository URL from Terraform output
get_ecr_url() {
    log_info "Getting ECR repository URL from Terraform..."
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Navigate to the parent directory where Terraform files are
    cd "$SCRIPT_DIR/.."
    
    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        log_info "Initializing Terraform..."
        terraform init
    fi
    
    # Get ECR repository URL
    ECR_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
    
    if [ -z "$ECR_URL" ]; then
        log_error "Could not get ECR repository URL from Terraform output."
        log_info "Please run 'terraform apply' first to create the ECR repository."
        exit 1
    fi
    
    log_success "ECR Repository URL: $ECR_URL"
    cd "$SCRIPT_DIR"
}

# Login to ECR
login_to_ecr() {
    log_info "Logging in to ECR..."
    
    # Get ECR login token
    aws ecr get-login-password --region $(aws configure get region) | \
    docker login --username AWS --password-stdin $ECR_URL
    
    if [ $? -eq 0 ]; then
        log_success "Successfully logged in to ECR"
    else
        log_error "Failed to login to ECR"
        exit 1
    fi
}

# Build Docker image
build_image() {
    log_info "Building Docker image..."
    
    # Build the image
    docker build -t $APP_NAME:$TAG .
    
    if [ $? -eq 0 ]; then
        log_success "Docker image built successfully"
    else
        log_error "Failed to build Docker image"
        exit 1
    fi
}

# Tag Docker image for ECR
tag_image() {
    log_info "Tagging image for ECR..."
    
    docker tag $APP_NAME:$TAG $ECR_URL:$TAG
    
    if [ $? -eq 0 ]; then
        log_success "Image tagged successfully"
    else
        log_error "Failed to tag image"
        exit 1
    fi
}

# Push Docker image to ECR
push_image() {
    log_info "Pushing image to ECR..."
    
    docker push $ECR_URL:$TAG
    
    if [ $? -eq 0 ]; then
        log_success "Image pushed successfully to ECR"
    else
        log_error "Failed to push image to ECR"
        exit 1
    fi
}

# Clean up local images
cleanup() {
    log_info "Cleaning up local images..."
    
    # Remove local tagged image
    docker rmi $APP_NAME:$TAG 2>/dev/null || true
    docker rmi $ECR_URL:$TAG 2>/dev/null || true
    
    log_success "Cleanup completed"
}

# Main execution
main() {
    log_info "Starting build and push process for $APP_NAME"
    log_info "Tag: $TAG"
    log_info "Environment: $ENVIRONMENT"
    log_info "Service: $SERVICE_NAME"
    
    # Pre-flight checks
    check_aws_cli
    check_docker
    get_ecr_url
    login_to_ecr
    
    # Build and push
    build_image
    tag_image
    push_image
    
    # Cleanup
    cleanup
    
    log_success "Build and push completed successfully!"
    log_info "Image available at: $ECR_URL:$TAG"
    
    # Output for Helm chart
    echo ""
    log_info "📋 For Helm chart deployment.yaml, use:"
    log_info "   image: $ECR_URL:$TAG"
}

# Run main function
main "$@"
