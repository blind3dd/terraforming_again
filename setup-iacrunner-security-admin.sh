#!/bin/bash

# Setup Script for iacrunner and security-admin Users
# This script sets up secure configurations for both users

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

print_header() {
    echo
    print_status $BLUE "=========================================="
    print_status $BLUE "$1"
    print_status $BLUE "=========================================="
    echo
}

# Setup profiles for both users
setup_user_profiles() {
    print_header "👥 Setting Up iacrunner and security-admin Profiles"
    
    print_status $BLUE "🔧 Setting up profiles for:"
    print_status $BLUE "  - iacrunner (Infrastructure as Code)"
    print_status $BLUE "  - security-admin (Security & Administration)"
    echo
    
    # Backup existing files
    if [ -f ~/.aws/credentials ]; then
        cp ~/.aws/credentials ~/.aws/credentials.backup.$(date +%s)
        print_status $BLUE "📁 Backed up existing credentials"
    fi
    
    if [ -f ~/.aws/config ]; then
        cp ~/.aws/config ~/.aws/config.backup.$(date +%s)
        print_status $BLUE "📁 Backed up existing config"
    fi
    
    # Create new credentials file
    mkdir -p ~/.aws
    cat > ~/.aws/credentials << 'EOF'
# AWS Credentials for iacrunner and security-admin
# Use: aws --profile <profile-name> <command>

[iacrunner]
aws_access_key_id = YOUR_IACRUNNER_ACCESS_KEY
aws_secret_access_key = YOUR_IACRUNNER_SECRET_KEY

[security-admin]
aws_access_key_id = YOUR_SECURITY_ADMIN_ACCESS_KEY
aws_secret_access_key = YOUR_SECURITY_ADMIN_SECRET_KEY
EOF
    
    # Create new config file with specific settings for each user
    cat > ~/.aws/config << 'EOF'
# AWS Configuration for iacrunner and security-admin
# Use: aws --profile <profile-name> <command>

[profile iacrunner]
region = us-east-1
output = json
# This user is for Terraform and infrastructure operations

[profile security-admin]
region = us-east-1
output = json
# This user is for security and administrative tasks
EOF
    
    print_status $GREEN "✅ Profile structure created for both users"
    print_status $YELLOW "⚠️  Please update ~/.aws/credentials with your actual access keys"
    echo
    
    print_status $BLUE "📋 Next steps:"
    print_status $BLUE "  1. Edit ~/.aws/credentials and replace:"
    print_status $BLUE "     - YOUR_IACRUNNER_ACCESS_KEY with iacrunner's access key"
    print_status $BLUE "     - YOUR_IACRUNNER_SECRET_KEY with iacrunner's secret key"
    print_status $BLUE "     - YOUR_SECURITY_ADMIN_ACCESS_KEY with security-admin's access key"
    print_status $BLUE "     - YOUR_SECURITY_ADMIN_SECRET_KEY with security-admin's secret key"
    print_status $BLUE "  2. Test each profile:"
    print_status $BLUE "     - aws --profile iacrunner sts get-caller-identity"
    print_status $BLUE "     - aws --profile security-admin sts get-caller-identity"
}

# Add credentials for iacrunner
add_iacrunner_credentials() {
    print_header "🔧 Adding Credentials for iacrunner"
    
    print_status $BLUE "iacrunner is for Infrastructure as Code operations (Terraform, etc.)"
    echo
    
    read -p "Enter AWS Access Key ID for iacrunner: " access_key
    read -p "Enter AWS Secret Access Key for iacrunner: " -s secret_key
    echo
    read -p "Enter AWS region for iacrunner (default: us-east-1): " region
    region=${region:-us-east-1}
    
    # Update credentials file
    if [ -f ~/.aws/credentials ]; then
        # Remove existing iacrunner profile if it exists
        sed -i "/\[iacrunner\]/,/^$/d" ~/.aws/credentials
    else
        mkdir -p ~/.aws
        touch ~/.aws/credentials
    fi
    
    # Add iacrunner profile
    cat >> ~/.aws/credentials << EOF

[iacrunner]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
EOF
    
    # Update config file
    if [ -f ~/.aws/config ]; then
        # Remove existing iacrunner profile if it exists
        sed -i "/\[profile iacrunner\]/,/^$/d" ~/.aws/config
    else
        mkdir -p ~/.aws
        touch ~/.aws/config
    fi
    
    # Add iacrunner profile config
    cat >> ~/.aws/config << EOF

[profile iacrunner]
region = $region
output = json
# This user is for Terraform and infrastructure operations
EOF
    
    print_status $GREEN "✅ Credentials added for iacrunner"
    
    # Test the credentials
    print_status $BLUE "🧪 Testing iacrunner credentials..."
    if aws --profile iacrunner sts get-caller-identity &> /dev/null; then
        local account_id=$(aws --profile iacrunner sts get-caller-identity --query Account --output text)
        local user_arn=$(aws --profile iacrunner sts get-caller-identity --query Arn --output text)
        print_status $GREEN "✅ iacrunner credentials are working!"
        print_status $BLUE "👤 Account: $account_id"
        print_status $BLUE "👤 User: $(basename "$user_arn")"
    else
        print_status $RED "❌ iacrunner credentials are not working"
        print_status $YELLOW "Please check your access key and secret key"
    fi
}

# Add credentials for security-admin
add_security_admin_credentials() {
    print_header "🔒 Adding Credentials for security-admin"
    
    print_status $BLUE "security-admin is for security and administrative tasks"
    echo
    
    read -p "Enter AWS Access Key ID for security-admin: " access_key
    read -p "Enter AWS Secret Access Key for security-admin: " -s secret_key
    echo
    read -p "Enter AWS region for security-admin (default: us-east-1): " region
    region=${region:-us-east-1}
    
    # Update credentials file
    if [ -f ~/.aws/credentials ]; then
        # Remove existing security-admin profile if it exists
        sed -i "/\[security-admin\]/,/^$/d" ~/.aws/credentials
    else
        mkdir -p ~/.aws
        touch ~/.aws/credentials
    fi
    
    # Add security-admin profile
    cat >> ~/.aws/credentials << EOF

[security-admin]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
EOF
    
    # Update config file
    if [ -f ~/.aws/config ]; then
        # Remove existing security-admin profile if it exists
        sed -i "/\[profile security-admin\]/,/^$/d" ~/.aws/config
    else
        mkdir -p ~/.aws
        touch ~/.aws/config
    fi
    
    # Add security-admin profile config
    cat >> ~/.aws/config << EOF

[profile security-admin]
region = $region
output = json
# This user is for security and administrative tasks
EOF
    
    print_status $GREEN "✅ Credentials added for security-admin"
    
    # Test the credentials
    print_status $BLUE "🧪 Testing security-admin credentials..."
    if aws --profile security-admin sts get-caller-identity &> /dev/null; then
        local account_id=$(aws --profile security-admin sts get-caller-identity --query Account --output text)
        local user_arn=$(aws --profile security-admin sts get-caller-identity --query Arn --output text)
        print_status $GREEN "✅ security-admin credentials are working!"
        print_status $BLUE "👤 Account: $account_id"
        print_status $BLUE "👤 User: $(basename "$user_arn")"
    else
        print_status $RED "❌ security-admin credentials are not working"
        print_status $YELLOW "Please check your access key and secret key"
    fi
}

# Test both profiles
test_both_profiles() {
    print_header "🧪 Testing Both Profiles"
    
    print_status $BLUE "🔍 Testing iacrunner profile..."
    if aws --profile iacrunner sts get-caller-identity &> /dev/null; then
        local account_id=$(aws --profile iacrunner sts get-caller-identity --query Account --output text)
        local user_arn=$(aws --profile iacrunner sts get-caller-identity --query Arn --output text)
        print_status $GREEN "✅ iacrunner: Working (Account: $account_id, User: $(basename "$user_arn"))"
    else
        print_status $RED "❌ iacrunner: Not working"
    fi
    
    echo
    
    print_status $BLUE "🔍 Testing security-admin profile..."
    if aws --profile security-admin sts get-caller-identity &> /dev/null; then
        local account_id=$(aws --profile security-admin sts get-caller-identity --query Account --output text)
        local user_arn=$(aws --profile security-admin sts get-caller-identity --query Arn --output text)
        print_status $GREEN "✅ security-admin: Working (Account: $account_id, User: $(basename "$user_arn"))"
    else
        print_status $RED "❌ security-admin: Not working"
    fi
}

# Create user-specific scripts
create_user_scripts() {
    print_header "📝 Creating User-Specific Scripts"
    
    # Create iacrunner script
    cat > ~/.aws/iacrunner-session.sh << 'EOF'
#!/bin/bash

# iacrunner Secure Session Script
# Creates temporary session with MFA for infrastructure operations

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Get MFA device ARN for iacrunner
mfa_arn=$(aws --profile iacrunner iam list-mfa-devices --user-name iacrunner --query 'MFADevices[0].SerialNumber' --output text)

if [ -z "$mfa_arn" ] || [ "$mfa_arn" = "None" ]; then
    print_status $YELLOW "⚠️  No MFA device found for iacrunner. Using regular credentials."
    exit 0
fi

print_status $BLUE "🔐 Getting MFA token for iacrunner..."
read -p "Enter 6-digit MFA code: " mfa_code

# Create session token
print_status $BLUE "🔧 Creating secure session token for iacrunner..."
session_response=$(aws --profile iacrunner sts get-session-token \
    --serial-number "$mfa_arn" \
    --token-code "$mfa_code" \
    --duration-seconds 3600)

# Extract credentials
access_key=$(echo "$session_response" | jq -r '.Credentials.AccessKeyId')
secret_key=$(echo "$session_response" | jq -r '.Credentials.SecretAccessKey')
session_token=$(echo "$session_response" | jq -r '.Credentials.SessionToken')

# Update credentials file
cat >> ~/.aws/credentials << CREDS_EOF

[iacrunner-session]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
aws_session_token = $session_token
CREDS_EOF

print_status $GREEN "✅ Secure session created for iacrunner (valid for 1 hour)"
print_status $BLUE "💡 Use: aws --profile iacrunner-session <command>"
print_status $BLUE "💡 For Terraform: export AWS_PROFILE=iacrunner-session"
EOF

    chmod +x ~/.aws/iacrunner-session.sh
    
    # Create security-admin script
    cat > ~/.aws/security-admin-session.sh << 'EOF'
#!/bin/bash

# security-admin Secure Session Script
# Creates temporary session with MFA for security operations

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Get MFA device ARN for security-admin
mfa_arn=$(aws --profile security-admin iam list-mfa-devices --user-name security-admin --query 'MFADevices[0].SerialNumber' --output text)

if [ -z "$mfa_arn" ] || [ "$mfa_arn" = "None" ]; then
    print_status $YELLOW "⚠️  No MFA device found for security-admin. Using regular credentials."
    exit 0
fi

print_status $BLUE "🔐 Getting MFA token for security-admin..."
read -p "Enter 6-digit MFA code: " mfa_code

# Create session token
print_status $BLUE "🔧 Creating secure session token for security-admin..."
session_response=$(aws --profile security-admin sts get-session-token \
    --serial-number "$mfa_arn" \
    --token-code "$mfa_code" \
    --duration-seconds 3600)

# Extract credentials
access_key=$(echo "$session_response" | jq -r '.Credentials.AccessKeyId')
secret_key=$(echo "$session_response" | jq -r '.Credentials.SecretAccessKey')
session_token=$(echo "$session_response" | jq -r '.Credentials.SessionToken')

# Update credentials file
cat >> ~/.aws/credentials << CREDS_EOF

[security-admin-session]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
aws_session_token = $session_token
CREDS_EOF

print_status $GREEN "✅ Secure session created for security-admin (valid for 1 hour)"
print_status $BLUE "💡 Use: aws --profile security-admin-session <command>"
EOF

    chmod +x ~/.aws/security-admin-session.sh
    
    print_status $GREEN "✅ User-specific scripts created:"
    print_status $GREEN "  - ~/.aws/iacrunner-session.sh"
    print_status $GREEN "  - ~/.aws/security-admin-session.sh"
}

# Create Terraform environment script
create_terraform_script() {
    print_header "🏗️ Creating Terraform Environment Script"
    
    cat > terraform-env.sh << 'EOF'
#!/bin/bash

# Terraform Environment Script
# Sets up the environment for Terraform operations with iacrunner

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status $BLUE "🏗️ Setting up Terraform environment with iacrunner"

# Set AWS profile for Terraform
export AWS_PROFILE=iacrunner

# Test iacrunner credentials
if aws sts get-caller-identity &> /dev/null; then
    account_id=$(aws sts get-caller-identity --query Account --output text)
    user_arn=$(aws sts get-caller-identity --query Arn --output text)
    print_status $GREEN "✅ iacrunner credentials working"
    print_status $BLUE "👤 Account: $account_id"
    print_status $BLUE "👤 User: $(basename "$user_arn")"
else
    print_status $RED "❌ iacrunner credentials not working"
    print_status $YELLOW "Please run: ~/.aws/iacrunner-session.sh (if MFA is enabled)"
    exit 1
fi

# Set Terraform variables
export TF_VAR_aws_profile=iacrunner
export TF_VAR_environment=dev

print_status $GREEN "✅ Terraform environment ready"
print_status $BLUE "💡 Commands:"
print_status $BLUE "  - terraform init"
print_status $BLUE "  - terraform plan"
print_status $BLUE "  - terraform apply"
print_status $BLUE "  - terraform destroy"

# Start a new shell with the environment
exec $SHELL
EOF

    chmod +x terraform-env.sh
    print_status $GREEN "✅ Terraform environment script created: terraform-env.sh"
}

# Main function
main() {
    print_status $BLUE "👥 Setup for iacrunner and security-admin Users"
    echo
    
    print_status $YELLOW "This script will set up secure configurations for:"
    print_status $YELLOW "  - iacrunner (Infrastructure as Code operations)"
    print_status $YELLOW "  - security-admin (Security & administrative tasks)"
    echo
    
    print_status $BLUE "📋 Available options:"
    print_status $BLUE "  1. Setup profile structure"
    print_status $BLUE "  2. Add iacrunner credentials"
    print_status $BLUE "  3. Add security-admin credentials"
    print_status $BLUE "  4. Test both profiles"
    print_status $BLUE "  5. Create user-specific scripts"
    print_status $BLUE "  6. Create Terraform environment script"
    print_status $BLUE "  7. Do everything (recommended)"
    echo
    
    read -p "Choose option (1-7): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            setup_user_profiles
            ;;
        2)
            add_iacrunner_credentials
            ;;
        3)
            add_security_admin_credentials
            ;;
        4)
            test_both_profiles
            ;;
        5)
            create_user_scripts
            ;;
        6)
            create_terraform_script
            ;;
        7)
            setup_user_profiles
            echo
            add_iacrunner_credentials
            echo
            add_security_admin_credentials
            echo
            test_both_profiles
            echo
            create_user_scripts
            echo
            create_terraform_script
            ;;
        *)
            print_status $RED "❌ Invalid option"
            exit 1
            ;;
    esac
    
    print_header "🎉 Setup Complete!"
    
    print_status $GREEN "✅ iacrunner and security-admin setup complete"
    print_status $BLUE "💡 Usage:"
    print_status $BLUE "  - iacrunner: aws --profile iacrunner <command>"
    print_status $BLUE "  - security-admin: aws --profile security-admin <command>"
    print_status $BLUE "  - Terraform: ./terraform-env.sh"
    print_status $BLUE "  - Secure sessions: ~/.aws/iacrunner-session.sh"
    print_status $BLUE "  - Secure sessions: ~/.aws/security-admin-session.sh"
    echo
    
    print_status $YELLOW "🔒 Security Features:"
    print_status $YELLOW "  - Separate users for different purposes"
    print_status $YELLOW "  - MFA support for both users"
    print_status $YELLOW "  - Secure session management"
    print_status $YELLOW "  - Terraform environment isolation"
}

# Run main function
main "$@"
