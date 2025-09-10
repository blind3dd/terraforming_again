#!/bin/bash

# AWS Multi-User Management Script
# This script helps you manage multiple AWS users and profiles

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

# Check current AWS configuration
check_current_config() {
    print_header "🔍 Checking Current AWS Configuration"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_status $RED "❌ AWS CLI not installed"
        print_status $YELLOW "Install with: nix-env -iA nixpkgs.awscli2"
        exit 1
    fi
    
    print_status $GREEN "✅ AWS CLI is installed"
    aws --version
    
    # Check current credentials
    if [ -f ~/.aws/credentials ]; then
        print_status $BLUE "📁 Current ~/.aws/credentials:"
        cat ~/.aws/credentials
        echo
    else
        print_status $YELLOW "⚠️  ~/.aws/credentials not found"
    fi
    
    if [ -f ~/.aws/config ]; then
        print_status $BLUE "📁 Current ~/.aws/config:"
        cat ~/.aws/config
        echo
    else
        print_status $YELLOW "⚠️  ~/.aws/config not found"
    fi
    
    # Test current credentials
    print_status $BLUE "🧪 Testing current credentials..."
    if aws sts get-caller-identity &> /dev/null; then
        local account_id=$(aws sts get-caller-identity --query Account --output text)
        local user_arn=$(aws sts get-caller-identity --query Arn --output text)
        print_status $GREEN "✅ Current credentials are working"
        print_status $BLUE "👤 Account: $account_id"
        print_status $BLUE "👤 User: $(basename "$user_arn")"
        return 0
    else
        print_status $RED "❌ Current credentials are not working"
        return 1
    fi
}

# Setup multiple user profiles
setup_multiple_profiles() {
    print_header "👥 Setting Up Multiple User Profiles"
    
    print_status $YELLOW "You have two users. Let's set up profiles for both:"
    echo
    
    # Get user information
    read -p "Enter name for first user (e.g., 'admin', 'dev', 'personal'): " user1_name
    read -p "Enter name for second user (e.g., 'terraform', 'ci', 'production'): " user2_name
    
    if [ -z "$user1_name" ] || [ -z "$user2_name" ]; then
        print_status $RED "❌ User names cannot be empty"
        exit 1
    fi
    
    print_status $BLUE "🔧 Setting up profiles: $user1_name and $user2_name"
    
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
    cat > ~/.aws/credentials << EOF
# AWS Credentials for Multiple Users
# Use: aws --profile <profile-name> <command>

[$user1_name]
aws_access_key_id = YOUR_ACCESS_KEY_1
aws_secret_access_key = YOUR_SECRET_KEY_1

[$user2_name]
aws_access_key_id = YOUR_ACCESS_KEY_2
aws_secret_access_key = YOUR_SECRET_KEY_2
EOF
    
    # Create new config file
    cat > ~/.aws/config << EOF
# AWS Configuration for Multiple Users
# Use: aws --profile <profile-name> <command>

[profile $user1_name]
region = us-east-1
output = json

[profile $user2_name]
region = us-east-1
output = json
EOF
    
    print_status $GREEN "✅ Profile structure created"
    print_status $YELLOW "⚠️  Please update ~/.aws/credentials with your actual access keys"
    echo
    
    print_status $BLUE "📋 Next steps:"
    print_status $BLUE "  1. Edit ~/.aws/credentials and replace:"
    print_status $BLUE "     - YOUR_ACCESS_KEY_1 with your first user's access key"
    print_status $BLUE "     - YOUR_SECRET_KEY_1 with your first user's secret key"
    print_status $BLUE "     - YOUR_ACCESS_KEY_2 with your second user's access key"
    print_status $BLUE "     - YOUR_SECRET_KEY_2 with your second user's secret key"
    print_status $BLUE "  2. Test each profile:"
    print_status $BLUE "     - aws --profile $user1_name sts get-caller-identity"
    print_status $BLUE "     - aws --profile $user2_name sts get-caller-identity"
}

# Add credentials for a specific user
add_user_credentials() {
    print_header "🔑 Adding Credentials for Specific User"
    
    print_status $YELLOW "Which user do you want to add credentials for?"
    print_status $YELLOW "1. First user"
    print_status $YELLOW "2. Second user"
    print_status $YELLOW "3. Add new user"
    
    read -p "Choose option (1-3): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            read -p "Enter profile name for first user: " profile_name
            ;;
        2)
            read -p "Enter profile name for second user: " profile_name
            ;;
        3)
            read -p "Enter profile name for new user: " profile_name
            ;;
        *)
            print_status $RED "❌ Invalid option"
            exit 1
            ;;
    esac
    
    if [ -z "$profile_name" ]; then
        print_status $RED "❌ Profile name cannot be empty"
        exit 1
    fi
    
    print_status $BLUE "🔧 Adding credentials for profile: $profile_name"
    
    read -p "Enter AWS Access Key ID: " access_key
    read -p "Enter AWS Secret Access Key: " -s secret_key
    echo
    read -p "Enter AWS region (default: us-east-1): " region
    region=${region:-us-east-1}
    
    # Add to credentials file
    if [ -f ~/.aws/credentials ]; then
        # Remove existing profile if it exists
        sed -i "/\[$profile_name\]/,/^$/d" ~/.aws/credentials
    else
        mkdir -p ~/.aws
        touch ~/.aws/credentials
    fi
    
    # Add new profile
    cat >> ~/.aws/credentials << EOF

[$profile_name]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
EOF
    
    # Add to config file
    if [ -f ~/.aws/config ]; then
        # Remove existing profile if it exists
        sed -i "/\[profile $profile_name\]/,/^$/d" ~/.aws/config
    else
        mkdir -p ~/.aws
        touch ~/.aws/config
    fi
    
    # Add new profile config
    cat >> ~/.aws/config << EOF

[profile $profile_name]
region = $region
output = json
EOF
    
    print_status $GREEN "✅ Credentials added for profile: $profile_name"
    
    # Test the credentials
    print_status $BLUE "🧪 Testing credentials..."
    if aws --profile "$profile_name" sts get-caller-identity &> /dev/null; then
        local account_id=$(aws --profile "$profile_name" sts get-caller-identity --query Account --output text)
        local user_arn=$(aws --profile "$profile_name" sts get-caller-identity --query Arn --output text)
        print_status $GREEN "✅ Credentials are working!"
        print_status $BLUE "👤 Account: $account_id"
        print_status $BLUE "👤 User: $(basename "$user_arn")"
    else
        print_status $RED "❌ Credentials are not working"
        print_status $YELLOW "Please check your access key and secret key"
    fi
}

# Test all profiles
test_all_profiles() {
    print_header "🧪 Testing All Profiles"
    
    if [ ! -f ~/.aws/credentials ]; then
        print_status $RED "❌ No credentials file found"
        return 1
    fi
    
    # Extract profile names from credentials file
    local profiles=$(grep '^\[' ~/.aws/credentials | sed 's/\[//g' | sed 's/\]//g')
    
    if [ -z "$profiles" ]; then
        print_status $RED "❌ No profiles found in credentials file"
        return 1
    fi
    
    print_status $BLUE "🔍 Found profiles: $profiles"
    echo
    
    for profile in $profiles; do
        print_status $BLUE "🧪 Testing profile: $profile"
        
        if aws --profile "$profile" sts get-caller-identity &> /dev/null; then
            local account_id=$(aws --profile "$profile" sts get-caller-identity --query Account --output text)
            local user_arn=$(aws --profile "$profile" sts get-caller-identity --query Arn --output text)
            print_status $GREEN "✅ $profile: Working (Account: $account_id, User: $(basename "$user_arn"))"
        else
            print_status $RED "❌ $profile: Not working"
        fi
        echo
    done
}

# Create profile management script
create_profile_management_script() {
    print_header "📝 Creating Profile Management Script"
    
    cat > ~/.aws/profile-manager.sh << 'EOF'
#!/bin/bash

# AWS Profile Manager Script
# Helps manage multiple AWS profiles

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

case "$1" in
    "list")
        print_status $BLUE "📋 Available AWS profiles:"
        if [ -f ~/.aws/credentials ]; then
            grep '^\[' ~/.aws/credentials | sed 's/\[//g' | sed 's/\]//g'
        else
            print_status $YELLOW "No profiles found"
        fi
        ;;
    "test")
        print_status $BLUE "🧪 Testing all profiles..."
        if [ -f ~/.aws/credentials ]; then
            profiles=$(grep '^\[' ~/.aws/credentials | sed 's/\[//g' | sed 's/\]//g')
            for profile in $profiles; do
                if aws --profile "$profile" sts get-caller-identity &> /dev/null; then
                    account_id=$(aws --profile "$profile" sts get-caller-identity --query Account --output text)
                    print_status $GREEN "✅ $profile: Working (Account: $account_id)"
                else
                    print_status $RED "❌ $profile: Not working"
                fi
            done
        fi
        ;;
    "use")
        if [ -z "$2" ]; then
            print_status $YELLOW "Usage: $0 use <profile-name>"
            exit 1
        fi
        print_status $BLUE "🔄 Switching to profile: $2"
        export AWS_PROFILE="$2"
        print_status $GREEN "✅ Now using profile: $2"
        print_status $BLUE "💡 Use: aws sts get-caller-identity (no --profile needed)"
        ;;
    "current")
        if [ -n "$AWS_PROFILE" ]; then
            print_status $BLUE "👤 Current profile: $AWS_PROFILE"
        else
            print_status $BLUE "👤 Using default profile"
        fi
        ;;
    *)
        print_status $BLUE "AWS Profile Manager"
        echo
        print_status $YELLOW "Usage: $0 <command>"
        echo
        print_status $YELLOW "Commands:"
        print_status $YELLOW "  list    - List all available profiles"
        print_status $YELLOW "  test    - Test all profiles"
        print_status $YELLOW "  use     - Switch to a specific profile"
        print_status $YELLOW "  current - Show current profile"
        ;;
esac
EOF

    chmod +x ~/.aws/profile-manager.sh
    print_status $GREEN "✅ Profile manager script created: ~/.aws/profile-manager.sh"
}

# Create secure setup for multiple users
create_secure_setup() {
    print_header "🔒 Creating Secure Setup for Multiple Users"
    
    print_status $YELLOW "Security recommendations for multiple users:"
    print_status $YELLOW "  1. Use different users for different purposes"
    print_status $YELLOW "  2. Apply least privilege principle"
    print_status $YELLOW "  3. Enable MFA for all users"
    print_status $YELLOW "  4. Use different regions if needed"
    print_status $YELLOW "  5. Regular credential rotation"
    echo
    
    print_status $BLUE "🔧 Creating secure session scripts for each user..."
    
    # Create secure session script template
    cat > ~/.aws/secure-session-template.sh << 'EOF'
#!/bin/bash

# Secure AWS Session Script Template
# Copy this script for each user and customize

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

# Configuration
PROFILE_NAME="YOUR_PROFILE_NAME"
USER_NAME="YOUR_USER_NAME"

# Get MFA device ARN
mfa_arn=$(aws --profile "$PROFILE_NAME" iam list-mfa-devices --user-name "$USER_NAME" --query 'MFADevices[0].SerialNumber' --output text)

if [ -z "$mfa_arn" ] || [ "$mfa_arn" = "None" ]; then
    print_status $YELLOW "⚠️  No MFA device found for $USER_NAME. Using regular credentials."
    exit 0
fi

print_status $BLUE "🔐 Getting MFA token for $USER_NAME..."
read -p "Enter 6-digit MFA code: " mfa_code

# Create session token
print_status $BLUE "🔧 Creating secure session token..."
session_response=$(aws --profile "$PROFILE_NAME" sts get-session-token \
    --serial-number "$mfa_arn" \
    --token-code "$mfa_code" \
    --duration-seconds 3600)

# Extract credentials
access_key=$(echo "$session_response" | jq -r '.Credentials.AccessKeyId')
secret_key=$(echo "$session_response" | jq -r '.Credentials.SecretAccessKey')
session_token=$(echo "$session_response" | jq -r '.Credentials.SessionToken')

# Update credentials file
cat >> ~/.aws/credentials << CREDS_EOF

[$PROFILE_NAME-session]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
aws_session_token = $session_token
CREDS_EOF

print_status $GREEN "✅ Secure session created for $USER_NAME (valid for 1 hour)"
print_status $BLUE "💡 Use: aws --profile $PROFILE_NAME-session <command>"
EOF

    chmod +x ~/.aws/secure-session-template.sh
    print_status $GREEN "✅ Secure session template created: ~/.aws/secure-session-template.sh"
    
    print_status $BLUE "💡 To create secure sessions for each user:"
    print_status $BLUE "  1. Copy the template: cp ~/.aws/secure-session-template.sh ~/.aws/secure-session-USER1.sh"
    print_status $BLUE "  2. Edit the script and replace YOUR_PROFILE_NAME and YOUR_USER_NAME"
    print_status $BLUE "  3. Make it executable: chmod +x ~/.aws/secure-session-USER1.sh"
    print_status $BLUE "  4. Run: ~/.aws/secure-session-USER1.sh"
}

# Main function
main() {
    print_status $BLUE "👥 AWS Multi-User Management Script"
    echo
    
    print_status $YELLOW "This script helps you manage multiple AWS users securely."
    echo
    
    # Check current configuration
    check_current_config
    echo
    
    print_status $BLUE "📋 Available options:"
    print_status $BLUE "  1. Setup multiple user profiles"
    print_status $BLUE "  2. Add credentials for specific user"
    print_status $BLUE "  3. Test all profiles"
    print_status $BLUE "  4. Create profile management script"
    print_status $BLUE "  5. Create secure setup"
    echo
    
    read -p "Choose option (1-5): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            setup_multiple_profiles
            ;;
        2)
            add_user_credentials
            ;;
        3)
            test_all_profiles
            ;;
        4)
            create_profile_management_script
            ;;
        5)
            create_secure_setup
            ;;
        *)
            print_status $RED "❌ Invalid option"
            exit 1
            ;;
    esac
    
    print_header "🎉 Multi-User Setup Complete!"
    
    print_status $GREEN "✅ Multi-user AWS configuration ready"
    print_status $BLUE "💡 Next steps:"
    print_status $BLUE "  - Use: ~/.aws/profile-manager.sh list (list profiles)"
    print_status $BLUE "  - Use: ~/.aws/profile-manager.sh test (test all profiles)"
    print_status $BLUE "  - Use: aws --profile <profile-name> <command> (use specific profile)"
    print_status $BLUE "  - Use: export AWS_PROFILE=<profile-name> (set default profile)"
    echo
    
    print_status $YELLOW "🔒 Security Tips:"
    print_status $YELLOW "  - Use different users for different purposes"
    print_status $YELLOW "  - Enable MFA for all users"
    print_status $YELLOW "  - Rotate credentials regularly"
    print_status $YELLOW "  - Use least privilege principle"
}

# Run main function
main "$@"
