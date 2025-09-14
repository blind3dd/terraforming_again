#!/bin/bash

# Terraform Environment Management Script
# This script helps manage different Terraform environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Available environments
ENVIRONMENTS=("dev" "test" "sandbox")

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <environment> <command> [options]"
    echo ""
    echo "Environments:"
    for env in "${ENVIRONMENTS[@]}"; do
        echo "  - $env"
    done
    echo ""
    echo "Commands:"
    echo "  init        Initialize Terraform in the environment"
    echo "  plan        Create a Terraform plan"
    echo "  apply       Apply Terraform configuration"
    echo "  destroy     Destroy Terraform resources"
    echo "  validate    Validate Terraform configuration"
    echo "  output      Show Terraform outputs"
    echo "  list        List all environments"
    echo "  create      Create a new environment"
    echo ""
    echo "Examples:"
    echo "  $0 dev init"
    echo "  $0 test plan"
    echo "  $0 dev apply"
    echo "  $0 test validate"
}

# Function to validate environment
validate_environment() {
    local env=$1
    if [[ ! " ${ENVIRONMENTS[@]} " =~ " ${env} " ]]; then
        print_error "Invalid environment: $env"
        print_info "Available environments: ${ENVIRONMENTS[*]}"
        exit 1
    fi
}

# Function to check if environment directory exists
check_environment_exists() {
    local env=$1
    if [[ ! -d "$SCRIPT_DIR/$env" ]]; then
        print_error "Environment directory does not exist: $SCRIPT_DIR/$env"
        exit 1
    fi
}

# Function to run terraform command in environment
run_terraform() {
    local env=$1
    local command=$2
    shift 2
    local args=("$@")
    
    local env_dir="$SCRIPT_DIR/$env"
    
    print_info "Running 'terraform $command' in $env environment..."
    print_info "Environment directory: $env_dir"
    
    cd "$env_dir"
    
    case $command in
        "init")
            terraform init
            ;;
        "plan")
            terraform plan "${args[@]}"
            ;;
        "apply")
            terraform apply "${args[@]}"
            ;;
        "destroy")
            terraform destroy "${args[@]}"
            ;;
        "validate")
            terraform validate
            ;;
        "output")
            terraform output "${args[@]}"
            ;;
        *)
            terraform "$command" "${args[@]}"
            ;;
    esac
    
    print_success "Terraform command completed successfully"
}

# Function to list environments
list_environments() {
    print_info "Available environments:"
    for env in "${ENVIRONMENTS[@]}"; do
        if [[ -d "$SCRIPT_DIR/$env" ]]; then
            print_success "  ✓ $env (exists)"
        else
            print_warning "  ✗ $env (missing)"
        fi
    done
}

# Function to create new environment
create_environment() {
    local env=$1
    
    if [[ -d "$SCRIPT_DIR/$env" ]]; then
        print_error "Environment $env already exists"
        exit 1
    fi
    
    print_info "Creating new environment: $env"
    
    # Create environment directory
    mkdir -p "$SCRIPT_DIR/$env"
    
    # Copy from test environment as template
    if [[ -d "$SCRIPT_DIR/test" ]]; then
        print_info "Copying test environment as template..."
        cp -r "$SCRIPT_DIR/test"/* "$SCRIPT_DIR/$env/"
        
        # Update environment-specific values
        sed -i.bak "s/environment = \"test\"/environment = \"$env\"/g" "$SCRIPT_DIR/$env/terraform.tfvars"
        sed -i.bak "s/test\.internal/$env.internal/g" "$SCRIPT_DIR/$env/terraform.tfvars"
        sed -i.bak "s/database_ci_test/database_ci_$env/g" "$SCRIPT_DIR/$env/terraform.tfvars"
        sed -i.bak "s/10\.1\.0\.0\/16/10.$((RANDOM % 255)).0.0\/16/g" "$SCRIPT_DIR/$env/terraform.tfvars"
        
        # Clean up backup files
        rm -f "$SCRIPT_DIR/$env"/*.bak
        
        print_success "Environment $env created successfully"
        print_info "Please review and update terraform.tfvars before applying"
    else
        print_error "Test environment not found. Cannot create template."
        exit 1
    fi
}

# Main script logic
main() {
    if [[ $# -lt 1 ]]; then
        show_usage
        exit 1
    fi
    
    local command=$1
    
    case $command in
        "list")
            list_environments
            ;;
        "create")
            if [[ $# -lt 2 ]]; then
                print_error "Environment name required for create command"
                exit 1
            fi
            create_environment "$2"
            ;;
        *)
            if [[ $# -lt 2 ]]; then
                print_error "Environment and command required"
                show_usage
                exit 1
            fi
            
            local env=$1
            local terraform_command=$2
            shift 2
            local args=("$@")
            
            validate_environment "$env"
            check_environment_exists "$env"
            run_terraform "$env" "$terraform_command" "${args[@]}"
            ;;
    esac
}

# Run main function with all arguments
main "$@"
