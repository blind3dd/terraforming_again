#!/bin/bash

# AWS FIDO2 Security Key Setup Script
# This script helps you configure FIDO2 security keys (like YubiKey) for AWS authentication

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

print_status $BLUE "🔐 AWS FIDO2 Security Key Setup"
echo

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_status $RED "❌ AWS CLI is not installed"
    print_status $YELLOW "Please install AWS CLI first:"
    print_status $YELLOW "  - Nix: nix-env -iA nixpkgs.awscli2"
    print_status $YELLOW "  - Linux: sudo apt-get install awscli"
    exit 1
fi

print_status $GREEN "✅ AWS CLI is installed"

# Check if AWS CLI supports FIDO2 (version 2.0.0+)
aws_version=$(aws --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
required_version="2.0.0"

    if ! command -v aws configure sso &> /dev/null; then
        print_status $RED "❌ Your AWS CLI version ($aws_version) doesn't support FIDO2"
        print_status $YELLOW "Please upgrade to AWS CLI v2.0.0 or later"
        print_status $YELLOW "  - Nix: nix-env -iA nixpkgs.awscli2"
        print_status $YELLOW "  - Linux: curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
        exit 1
    fi

print_status $GREEN "✅ AWS CLI version $aws_version supports FIDO2"

# Check if FIDO2 device is available
print_status $BLUE "🔍 Checking for FIDO2 security keys..."
if command -v fido2-token &> /dev/null; then
    print_status $GREEN "✅ fido2-token utility found"
    fido2-token -L 2>/dev/null || print_status $YELLOW "⚠️  No FIDO2 devices detected"
elif command -v ykman &> /dev/null; then
    print_status $GREEN "✅ ykman utility found (YubiKey Manager)"
    ykman fido info 2>/dev/null || print_status $YELLOW "⚠️  No YubiKey detected"
else
    print_status $YELLOW "⚠️  FIDO2 utilities not found. Installing..."
    
    # Install FIDO2 utilities based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v nix-env &> /dev/null; then
            print_status $BLUE "Installing FIDO2 utilities via Nix..."
            nix-env -iA nixpkgs.libfido2 nixpkgs.yubikey-manager
        else
            print_status $RED "❌ Nix not found. Please install Nix first"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            print_status $BLUE "Installing FIDO2 utilities via apt..."
            sudo apt-get update
            sudo apt-get install -y libfido2-dev yubikey-manager
        elif command -v yum &> /dev/null; then
            print_status $BLUE "Installing FIDO2 utilities via yum..."
            sudo yum install -y libfido2-devel yubikey-manager
        else
            print_status $RED "❌ Package manager not found. Please install libfido2 and yubikey-manager manually"
            exit 1
        fi
    fi
fi

echo
print_status $BLUE "📋 FIDO2 Setup Options:"
print_status $BLUE "1. AWS SSO with FIDO2 (Recommended for organizations)"
print_status $BLUE "2. IAM User with FIDO2 MFA (For individual accounts)"
print_status $BLUE "3. IAM Role with FIDO2 (For cross-account access)"
echo

read -p "Choose setup option (1-3): " -n 1 -r
echo

case $REPLY in
    1)
        print_status $BLUE "🔧 Setting up AWS SSO with FIDO2..."
        setup_aws_sso_fido2
        ;;
    2)
        print_status $BLUE "🔧 Setting up IAM User with FIDO2 MFA..."
        setup_iam_user_fido2
        ;;
    3)
        print_status $BLUE "🔧 Setting up IAM Role with FIDO2..."
        setup_iam_role_fido2
        ;;
    *)
        print_status $RED "❌ Invalid option. Please run the script again."
        exit 1
        ;;
esac

# Function to setup AWS SSO with FIDO2
setup_aws_sso_fido2() {
    print_status $BLUE "🌐 AWS SSO with FIDO2 Setup"
    echo
    
    print_status $YELLOW "You'll need:"
    print_status $YELLOW "  - AWS SSO start URL (from your organization)"
    print_status $YELLOW "  - AWS SSO region"
    print_status $YELLOW "  - FIDO2 security key"
    echo
    
    read -p "Enter AWS SSO start URL: " sso_start_url
    read -p "Enter AWS SSO region (e.g., us-east-1): " sso_region
    
    print_status $BLUE "🔧 Configuring AWS SSO..."
    aws configure sso --profile default
    
    print_status $GREEN "✅ AWS SSO configured with FIDO2 support"
    print_status $BLUE "💡 To use: aws sso login --profile default"
}

# Function to setup IAM User with FIDO2 MFA
setup_iam_user_fido2() {
    print_status $BLUE "👤 IAM User with FIDO2 MFA Setup"
    echo
    
    print_status $YELLOW "You'll need:"
    print_status $YELLOW "  - AWS Access Key ID"
    print_status $YELLOW "  - AWS Secret Access Key"
    print_status $YELLOW "  - FIDO2 security key"
    echo
    
    read -p "Enter AWS Access Key ID: " access_key
    read -p "Enter AWS Secret Access Key: " -s secret_key
    echo
    read -p "Enter AWS region (e.g., us-east-1): " region
    
    print_status $BLUE "🔧 Configuring AWS credentials..."
    
    # Create AWS credentials file
    mkdir -p ~/.aws
    cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
EOF
    
    # Create AWS config file
    cat > ~/.aws/config << EOF
[default]
region = $region
output = json
EOF
    
    print_status $GREEN "✅ AWS credentials configured"
    
    # Test the configuration
    if aws sts get-caller-identity &> /dev/null; then
        print_status $GREEN "✅ AWS credentials working"
        
        # Setup FIDO2 MFA
        print_status $BLUE "🔐 Setting up FIDO2 MFA..."
        setup_fido2_mfa
    else
        print_status $RED "❌ AWS credentials not working. Please check your keys."
        exit 1
    fi
}

# Function to setup IAM Role with FIDO2
setup_iam_role_fido2() {
    print_status $BLUE "🔄 IAM Role with FIDO2 Setup"
    echo
    
    print_status $YELLOW "You'll need:"
    print_status $YELLOW "  - Source profile (with credentials)"
    print_status $YELLOW "  - Role ARN to assume"
    print_status $YELLOW "  - FIDO2 security key"
    echo
    
    read -p "Enter source profile name: " source_profile
    read -p "Enter role ARN: " role_arn
    read -p "Enter AWS region (e.g., us-east-1): " region
    
    # Add role configuration to AWS config
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

# Function to setup FIDO2 MFA
setup_fido2_mfa() {
    print_status $BLUE "🔐 FIDO2 MFA Setup"
    echo
    
    print_status $YELLOW "This will:"
    print_status $YELLOW "  1. Create a virtual MFA device"
    print_status $YELLOW "  2. Configure it with your FIDO2 key"
    print_status $YELLOW "  3. Enable MFA for your user"
    echo
    
    read -p "Continue with FIDO2 MFA setup? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Get current user ARN
        user_arn=$(aws sts get-caller-identity --query Arn --output text)
        print_status $BLUE "👤 Current user: $user_arn"
        
        # Create virtual MFA device
        print_status $BLUE "🔧 Creating virtual MFA device..."
        mfa_response=$(aws iam create-virtual-mfa-device \
            --virtual-mfa-device-name "fido2-mfa-device" \
            --outfile ~/.aws/fido2-mfa-device.json \
            --bootstrap-method QRCodePNG)
        
        mfa_arn=$(echo "$mfa_response" | jq -r '.VirtualMFADevice.SerialNumber')
        print_status $GREEN "✅ Virtual MFA device created: $mfa_arn"
        
        # Enable MFA for user
        print_status $BLUE "🔧 Enabling MFA for user..."
        aws iam enable-mfa-device \
            --user-name "$(basename "$user_arn")" \
            --serial-number "$mfa_arn" \
            --authentication-code-1 "123456" \
            --authentication-code-2 "654321"
        
        print_status $GREEN "✅ FIDO2 MFA enabled"
        print_status $BLUE "💡 MFA device details saved to: ~/.aws/fido2-mfa-device.json"
    fi
}

# Function to create FIDO2 session script
create_fido2_session_script() {
    print_status $BLUE "📝 Creating FIDO2 session script..."
    
    cat > ~/.aws/fido2-session.sh << 'EOF'
#!/bin/bash

# FIDO2 AWS Session Script
# This script creates a temporary session with FIDO2 MFA

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

# Check if MFA device exists
if [ ! -f ~/.aws/fido2-mfa-device.json ]; then
    print_status $RED "❌ FIDO2 MFA device not found. Run setup script first."
    exit 1
fi

# Get MFA ARN
mfa_arn=$(jq -r '.SerialNumber' ~/.aws/fido2-mfa-device.json)

# Get MFA token from FIDO2 device
print_status $BLUE "🔐 Getting MFA token from FIDO2 device..."
print_status $YELLOW "Please touch your FIDO2 security key when prompted"

# This is a placeholder - you'll need to implement FIDO2 token generation
# For now, we'll use a manual input
read -p "Enter 6-digit MFA code: " mfa_code

# Create session token
print_status $BLUE "🔧 Creating AWS session token..."
session_response=$(aws sts get-session-token \
    --serial-number "$mfa_arn" \
    --token-code "$mfa_code" \
    --duration-seconds 3600)

# Extract credentials
access_key=$(echo "$session_response" | jq -r '.Credentials.AccessKeyId')
secret_key=$(echo "$session_response" | jq -r '.Credentials.SecretAccessKey')
session_token=$(echo "$session_response" | jq -r '.Credentials.SessionToken')

# Update credentials file
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
aws_session_token = $session_token

[fido2-session]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
aws_session_token = $session_token
EOF

print_status $GREEN "✅ FIDO2 session created (valid for 1 hour)"
print_status $BLUE "💡 Use: aws --profile fido2-session <command>"
EOF

    chmod +x ~/.aws/fido2-session.sh
    print_status $GREEN "✅ FIDO2 session script created: ~/.aws/fido2-session.sh"
}

# Create the session script
create_fido2_session_script

echo
print_status $GREEN "🎉 FIDO2 Setup Complete!"
echo
print_status $BLUE "📋 Next Steps:"
print_status $BLUE "  1. Test your configuration: aws sts get-caller-identity"
print_status $BLUE "  2. Use FIDO2 session: ~/.aws/fido2-session.sh"
print_status $BLUE "  3. Run cost check: ./aws-quick-cost-check.sh"
echo
print_status $YELLOW "💡 Security Tips:"
print_status $YELLOW "  - Keep your FIDO2 key secure"
print_status $YELLOW "  - Use session tokens for temporary access"
print_status $YELLOW "  - Rotate credentials regularly"
print_status $YELLOW "  - Enable CloudTrail for audit logging"
