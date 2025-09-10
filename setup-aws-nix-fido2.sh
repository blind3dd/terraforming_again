#!/bin/bash

# Complete AWS FIDO2 Setup with Nix Package Manager
# This script handles everything: Nix packages, AWS credentials, and FIDO2 setup

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

# Check if Nix is installed
check_nix() {
    print_status $BLUE "🔍 Checking Nix package manager..."
    
    if ! command -v nix-env &> /dev/null; then
        print_status $RED "❌ Nix package manager not installed"
        print_status $YELLOW "Please install Nix first:"
        print_status $YELLOW "  - macOS: sh <(curl -L https://nixos.org/nix/install)"
        print_status $YELLOW "  - Linux: sh <(curl -L https://nixos.org/nix/install) --daemon"
        print_status $YELLOW "  - Or visit: https://nixos.org/download.html"
        exit 1
    fi
    
    print_status $GREEN "✅ Nix package manager found"
}

# Install required packages via Nix
install_nix_packages() {
    print_status $BLUE "📦 Installing required packages via Nix..."
    
    local packages=("awscli2" "jq" "libfido2" "yubikey-manager")
    
    for package in "${packages[@]}"; do
        if ! command -v "$package" &> /dev/null; then
            print_status $BLUE "Installing $package..."
            nix-env -iA "nixpkgs.$package"
        else
            print_status $GREEN "✅ $package already installed"
        fi
    done
    
    print_status $GREEN "✅ All required packages installed"
}

# Setup AWS credentials in ~/.aws
setup_aws_credentials() {
    print_status $BLUE "🔧 Setting up AWS credentials in ~/.aws..."
    
    # Create ~/.aws directory if it doesn't exist
    mkdir -p ~/.aws
    
    print_status $YELLOW "Choose your AWS authentication method:"
    print_status $YELLOW "1. Access Keys (IAM User)"
    print_status $YELLOW "2. AWS SSO"
    print_status $YELLOW "3. IAM Role (for cross-account access)"
    
    read -p "Choose option (1-3): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            setup_access_keys
            ;;
        2)
            setup_aws_sso
            ;;
        3)
            setup_iam_role
            ;;
        *)
            print_status $RED "❌ Invalid option"
            exit 1
            ;;
    esac
}

# Setup access keys
setup_access_keys() {
    print_status $BLUE "🔑 Setting up AWS Access Keys..."
    
    read -p "Enter AWS Access Key ID: " access_key
    read -p "Enter AWS Secret Access Key: " -s secret_key
    echo
    read -p "Enter AWS region (default: us-east-1): " region
    region=${region:-us-east-1}
    
    # Create credentials file
    cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
EOF
    
    # Create config file
    cat > ~/.aws/config << EOF
[default]
region = $region
output = json
EOF
    
    # Test credentials
    if aws sts get-caller-identity &> /dev/null; then
        local account_id=$(aws sts get-caller-identity --query Account --output text)
        local user_arn=$(aws sts get-caller-identity --query Arn --output text)
        print_status $GREEN "✅ AWS credentials configured successfully"
        print_status $BLUE "👤 Account: $account_id"
        print_status $BLUE "👤 User: $(basename "$user_arn")"
    else
        print_status $RED "❌ Invalid AWS credentials"
        exit 1
    fi
}

# Setup AWS SSO
setup_aws_sso() {
    print_status $BLUE "🌐 Setting up AWS SSO..."
    
    read -p "Enter AWS SSO start URL: " sso_start_url
    read -p "Enter AWS SSO region (default: us-east-1): " sso_region
    sso_region=${sso_region:-us-east-1}
    
    # Configure SSO
    aws configure sso --profile default
    
    # Test SSO
    if aws sso login --profile default &> /dev/null; then
        print_status $GREEN "✅ AWS SSO configured successfully"
    else
        print_status $RED "❌ AWS SSO configuration failed"
        exit 1
    fi
}

# Setup IAM Role
setup_iam_role() {
    print_status $BLUE "🔄 Setting up IAM Role..."
    
    read -p "Enter source profile name: " source_profile
    read -p "Enter role ARN: " role_arn
    read -p "Enter AWS region (default: us-east-1): " region
    region=${region:-us-east-1}
    
    # Add role configuration to config file
    cat >> ~/.aws/config << EOF

[profile $source_profile-role]
role_arn = $role_arn
source_profile = $source_profile
region = $region
output = json
EOF
    
    print_status $GREEN "✅ IAM Role configured"
    print_status $BLUE "💡 To use: aws --profile $source_profile-role sts get-caller-identity"
}

# Setup FIDO2 MFA
setup_fido2_mfa() {
    print_status $BLUE "🔐 Setting up FIDO2 MFA..."
    
    # Get current user info
    local user_arn=$(aws sts get-caller-identity --query Arn --output text)
    local user_name=$(basename "$user_arn")
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    
    print_status $BLUE "👤 Setting up FIDO2 for user: $user_name"
    
    # Check if FIDO2 device is available
    print_status $BLUE "🔍 Checking for FIDO2 device..."
    if command -v fido2-token &> /dev/null; then
        local devices=$(fido2-token -L 2>/dev/null || echo "")
        if [ -z "$devices" ]; then
            print_status $YELLOW "⚠️  No FIDO2 devices detected. Please insert your FIDO2 key."
            read -p "Press Enter when FIDO2 key is inserted..."
        fi
    elif command -v ykman &> /dev/null; then
        ykman fido info 2>/dev/null || {
            print_status $YELLOW "⚠️  No YubiKey detected. Please insert your YubiKey."
            read -p "Press Enter when YubiKey is inserted..."
        }
    else
        print_status $YELLOW "⚠️  FIDO2 utilities not found. Please ensure your FIDO2 key is inserted."
        read -p "Press Enter when FIDO2 key is ready..."
    fi
    
    # Create virtual MFA device
    print_status $BLUE "🔧 Creating virtual MFA device..."
    local mfa_response=$(aws iam create-virtual-mfa-device \
        --virtual-mfa-device-name "fido2-$(date +%s)" \
        --outfile ~/.aws/fido2-mfa-device.json \
        --bootstrap-method QRCodePNG 2>/dev/null || {
        print_status $YELLOW "⚠️  Virtual MFA device creation failed. Trying alternative method..."
        aws iam create-virtual-mfa-device \
            --virtual-mfa-device-name "fido2-$(date +%s)" \
            --outfile ~/.aws/fido2-mfa-device.json
    })
    
    local mfa_arn=$(jq -r '.VirtualMFADevice.SerialNumber' ~/.aws/fido2-mfa-device.json)
    print_status $GREEN "✅ Virtual MFA device created: $mfa_arn"
    
    # Create FIDO2 registration script
    create_fido2_registration_script "$mfa_arn" "$user_name"
    
    print_status $YELLOW "⚠️  FIDO2 registration requires manual steps:"
    print_status $YELLOW "1. Go to AWS Console → IAM → Users → $user_name → Security credentials"
    print_status $YELLOW "2. Click 'Assign MFA device'"
    print_status $YELLOW "3. Choose 'Security key (FIDO2)'"
    print_status $YELLOW "4. Register your FIDO2 key"
    print_status $YELLOW "5. Run the registration script: ~/.aws/register-fido2.sh"
    
    read -p "Press Enter when FIDO2 is registered in AWS Console..."
}

# Create FIDO2 registration script
create_fido2_registration_script() {
    local mfa_arn=$1
    local user_name=$2
    
    cat > ~/.aws/register-fido2.sh << EOF
#!/bin/bash

# FIDO2 Registration Script
# Run this after registering your FIDO2 key in AWS Console

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=\$1
    local message=\$2
    echo -e "\${color}\${message}\${NC}"
}

print_status \$BLUE "🔐 FIDO2 Registration Verification"

# Get the actual FIDO2 device ARN from AWS
print_status \$BLUE "🔍 Finding registered FIDO2 device..."
fido2_arn=\$(aws iam list-mfa-devices --user-name "$user_name" --query 'MFADevices[?contains(SerialNumber, \`fido\`)].SerialNumber' --output text)

if [ -n "\$fido2_arn" ] && [ "\$fido2_arn" != "None" ]; then
    print_status \$GREEN "✅ FIDO2 device found: \$fido2_arn"
    
    # Create session script
    cat > ~/.aws/fido2-session.sh << 'SESSION_EOF'
#!/bin/bash

# FIDO2 AWS Session Script
# Creates temporary session with FIDO2 MFA

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=\$1
    local message=\$2
    echo -e "\${color}\${message}\${NC}"
}

# Get FIDO2 device ARN
fido2_arn=\$(aws iam list-mfa-devices --user-name "$user_name" --query 'MFADevices[?contains(SerialNumber, \`fido\`)].SerialNumber' --output text)

if [ -z "\$fido2_arn" ] || [ "\$fido2_arn" = "None" ]; then
    print_status \$RED "❌ FIDO2 device not found. Please register it first."
    exit 1
fi

print_status \$BLUE "🔐 Getting MFA token from FIDO2 device..."
print_status \$YELLOW "Please touch your FIDO2 security key when prompted"

# For FIDO2, we need to get the token from the device
# This is a simplified version - you may need to implement actual FIDO2 token generation
read -p "Enter 6-digit MFA code from your FIDO2 device: " mfa_code

# Create session token
print_status \$BLUE "🔧 Creating AWS session token..."
session_response=\$(aws sts get-session-token \\
    --serial-number "\$fido2_arn" \\
    --token-code "\$mfa_code" \\
    --duration-seconds 3600)

# Extract credentials
access_key=\$(echo "\$session_response" | jq -r '.Credentials.AccessKeyId')
secret_key=\$(echo "\$session_response" | jq -r '.Credentials.SecretAccessKey')
session_token=\$(echo "\$session_response" | jq -r '.Credentials.SessionToken')

# Update credentials file
cat > ~/.aws/credentials << CREDS_EOF
[default]
aws_access_key_id = \$access_key
aws_secret_access_key = \$secret_key
aws_session_token = \$session_token

[fido2-session]
aws_access_key_id = \$access_key
aws_secret_access_key = \$secret_key
aws_session_token = \$session_token
CREDS_EOF

print_status \$GREEN "✅ FIDO2 session created (valid for 1 hour)"
print_status \$BLUE "💡 Use: aws --profile fido2-session <command>"
SESSION_EOF

    chmod +x ~/.aws/fido2-session.sh
    print_status \$GREEN "✅ FIDO2 session script created: ~/.aws/fido2-session.sh"
    
else
    print_status \$RED "❌ FIDO2 device not found. Please register it in AWS Console first."
    exit 1
fi
EOF

    chmod +x ~/.aws/register-fido2.sh
    print_status $GREEN "✅ FIDO2 registration script created: ~/.aws/register-fido2.sh"
}

# Create cost check script
create_cost_check_script() {
    print_status $BLUE "📝 Creating cost check script..."
    
    cat > ~/.aws/cost-check.sh << 'EOF'
#!/bin/bash

# Quick AWS Cost Check with FIDO2
# This script checks for billable resources

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if we have valid credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_status $YELLOW "⚠️  No valid AWS session. Creating FIDO2 session..."
    if [ -f ~/.aws/fido2-session.sh ]; then
        ~/.aws/fido2-session.sh
    else
        print_status $RED "❌ FIDO2 session script not found. Run setup first."
        exit 1
    fi
fi

account_id=$(aws sts get-caller-identity --query Account --output text)
print_status $GREEN "✅ Checking AWS Account: $account_id"
echo

# Quick cost checks
print_status $BLUE "🔍 Quick Cost Check - Most Expensive Resources"
echo

# EC2 instances
print_status $YELLOW "💰 EC2 Instances (Running):"
aws ec2 describe-instances \
    --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,InstanceType,LaunchTime]' \
    --output table 2>/dev/null || echo "  No running instances"

echo

# RDS instances
print_status $YELLOW "💰 RDS Instances:"
aws rds describe-db-instances \
    --query 'DBInstances[?DBInstanceStatus!=`deleted`].[DBInstanceIdentifier,DBInstanceClass,Engine,DBInstanceStatus]' \
    --output table 2>/dev/null || echo "  No RDS instances"

echo

# Unassociated Elastic IPs
print_status $YELLOW "💰 Unassociated Elastic IPs (cost money!):"
aws ec2 describe-addresses \
    --query 'Addresses[?AssociationId==null].[PublicIp,AllocationId]' \
    --output table 2>/dev/null || echo "  No unassociated Elastic IPs"

echo

# NAT Gateways
print_status $YELLOW "💰 NAT Gateways:"
aws ec2 describe-nat-gateways \
    --query 'NatGateways[?State!=`deleted`].[NatGatewayId,State,VpcId]' \
    --output table 2>/dev/null || echo "  No NAT Gateways"

echo

print_status $GREEN "✅ Cost check complete!"
EOF

    chmod +x ~/.aws/cost-check.sh
    print_status $GREEN "✅ Cost check script created: ~/.aws/cost-check.sh"
}

# Create Nix shell environment
create_nix_shell() {
    print_status $BLUE "📝 Creating Nix shell environment..."
    
    cat > shell.nix << 'EOF'
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    awscli2
    jq
    libfido2
    yubikey-manager
    terraform
    kubectl
    helm
  ];
  
  shellHook = ''
    echo "🔧 AWS Development Environment"
    echo "Available tools:"
    echo "  - aws (AWS CLI v2)"
    echo "  - jq (JSON processor)"
    echo "  - fido2-token (FIDO2 utilities)"
    echo "  - ykman (YubiKey Manager)"
    echo "  - terraform"
    echo "  - kubectl"
    echo "  - helm"
    echo ""
    echo "💡 Run: ~/.aws/cost-check.sh (to check AWS costs)"
    echo "💡 Run: ~/.aws/fido2-session.sh (to create FIDO2 session)"
  '';
}
EOF

    print_status $GREEN "✅ Nix shell environment created: shell.nix"
    print_status $BLUE "💡 To enter the environment: nix-shell"
}

# Main function
main() {
    print_status $BLUE "🚀 Complete AWS FIDO2 Setup with Nix"
    echo
    
    # Check Nix
    check_nix
    echo
    
    # Install packages
    install_nix_packages
    echo
    
    # Setup AWS credentials
    setup_aws_credentials
    echo
    
    # Setup FIDO2 MFA
    setup_fido2_mfa
    echo
    
    # Create helper scripts
    create_cost_check_script
    echo
    
    # Create Nix shell
    create_nix_shell
    echo
    
    print_status $GREEN "🎉 Complete Setup Finished!"
    echo
    print_status $BLUE "📋 Next Steps:"
    print_status $BLUE "  1. Register FIDO2 in AWS Console (see instructions above)"
    print_status $BLUE "  2. Run: ~/.aws/register-fido2.sh"
    print_status $BLUE "  3. Test: ~/.aws/cost-check.sh"
    print_status $BLUE "  4. Use: ~/.aws/fido2-session.sh (for temporary sessions)"
    print_status $BLUE "  5. Enter Nix environment: nix-shell"
    echo
    print_status $YELLOW "💡 Your ~/.aws directory now contains:"
    print_status $YELLOW "  - credentials (AWS access keys)"
    print_status $YELLOW "  - config (AWS configuration)"
    print_status $YELLOW "  - fido2-mfa-device.json (MFA device info)"
    print_status $YELLOW "  - register-fido2.sh (FIDO2 registration script)"
    print_status $YELLOW "  - fido2-session.sh (FIDO2 session script)"
    print_status $YELLOW "  - cost-check.sh (AWS cost checker)"
    echo
    print_status $YELLOW "🔒 Security Tips:"
    print_status $YELLOW "  - Keep your FIDO2 key secure"
    print_status $YELLOW "  - Use session tokens for temporary access"
    print_status $YELLOW "  - Enable CloudTrail for audit logging"
    print_status $YELLOW "  - Rotate credentials regularly"
}

# Run main function
main "$@"
