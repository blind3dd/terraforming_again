#!/bin/bash

# Simple YubiKey PIV Certificate Generation Script
# Generates certificates and provides manual installation instructions

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

# Check prerequisites
check_prerequisites() {
    print_header "🔍 Checking Prerequisites"
    
    print_status $BLUE "🔧 Checking required tools..."
    
    # Check if ykman is available
    if command -v ykman &> /dev/null; then
        print_status $GREEN "✅ YubiKey Manager available"
    else
        print_status $RED "❌ YubiKey Manager not found"
        print_status $YELLOW "💡 Install with: nix-env -iA nixpkgs.yubikey-manager"
        exit 1
    fi
    
    # Check if openssl is available
    if command -v openssl &> /dev/null; then
        print_status $GREEN "✅ OpenSSL available"
    else
        print_status $RED "❌ OpenSSL not found"
        print_status $YELLOW "💡 Install with: nix-env -iA nixpkgs.openssl"
        exit 1
    fi
    
    # Check if YubiKey is connected
    if ykman list &> /dev/null; then
        print_status $GREEN "✅ YubiKey detected"
    else
        print_status $RED "❌ YubiKey not detected"
        print_status $YELLOW "💡 Please connect your YubiKey and try again"
        exit 1
    fi
}

# Check current PIV status
check_piv_status() {
    print_header "🔑 Checking Current PIV Status"
    
    print_status $BLUE "🔍 Checking PIV configuration..."
    
    # Check PIV info
    if ykman piv info &> /dev/null; then
        print_status $GREEN "✅ PIV is enabled on YubiKey"
        
        # Check existing certificates
        print_status $BLUE "📋 Current PIV certificates:"
        ykman piv certificates list 2>/dev/null || print_status $YELLOW "⚠️  No PIV certificates found"
        
        # Check PIV slots
        print_status $BLUE "🔧 PIV slots status:"
        ykman piv info | grep -E "(Slot|Certificate)" || print_status $YELLOW "⚠️  Could not read PIV slots"
        
        # Explain PIV slot usage
        print_status $BLUE "📚 PIV Slot Usage:"
        print_status $BLUE "  - 9a: Authentication (CA certificates)"
        print_status $BLUE "  - 9c: Digital Signature (user certificates)"
        print_status $BLUE "  - 9e: Key Management (encryption keys)"
        print_status $BLUE "  - 9d: Card Authentication (optional)"
    else
        print_status $RED "❌ PIV not available on YubiKey"
        print_status $YELLOW "💡 Please enable PIV on your YubiKey first"
        exit 1
    fi
}

# Generate PIV certificates
generate_piv_certificates() {
    print_header "🔐 Generating PIV Certificates"
    
    print_status $BLUE "🔧 Generating PIV certificates for YubiKey..."
    
    # Create working directory
    WORK_DIR="$HOME/yubikey-certs"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    
    print_status $BLUE "📁 Working directory: $WORK_DIR"
    
    # Generate CA certificate
    print_status $BLUE "🔐 Generating CA certificate..."
    openssl req -x509 -newkey rsa:2048 -keyout ca-key.pem -out ca-cert.pem -days 365 -nodes \
        -subj "/C=US/ST=CA/L=San Francisco/O=CodeRed Alarm Tech/OU=IT/CN=YubiKey CA" \
        -extensions v3_ca -config <(
            echo '[req]'
            echo 'distinguished_name = req'
            echo '[v3_ca]'
            echo 'basicConstraints = critical,CA:TRUE'
            echo 'keyUsage = critical,keyCertSign,cRLSign'
        )
    
    # Generate user certificate
    print_status $BLUE "🔐 Generating user certificate..."
    openssl req -newkey rsa:2048 -keyout user-key.pem -out user-csr.pem -nodes \
        -subj "/C=US/ST=CA/L=San Francisco/O=CodeRed Alarm Tech/OU=IT/CN=$(whoami)@coderedalarmtech.com"
    
    # Create OpenSSL config file for user certificate
    cat > user-cert.conf << EOF
[v3_user]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = clientAuth,emailProtection
subjectAltName = email:$(whoami)@coderedalarmtech.com
EOF
    
    # Sign user certificate with CA
    openssl x509 -req -in user-csr.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial \
        -out user-cert.pem -days 365 -extensions v3_user -extfile user-cert.conf
    
    print_status $GREEN "✅ Certificates generated successfully"
    print_status $BLUE "📁 Certificates saved to: $WORK_DIR"
}

# Provide manual installation instructions
provide_installation_instructions() {
    print_header "📱 Manual Installation Instructions"
    
    print_status $YELLOW "🔐 You'll need to install these certificates manually using ykman."
    print_status $YELLOW "💡 The default PIV PIN is usually: 123456"
    print_status $YELLOW "💡 If you've changed it, use your custom PIN."
    echo
    
    print_status $BLUE "🔧 Installation commands:"
    echo
    print_status $GREEN "1. Install CA certificate to slot 9a (Authentication):"
    print_status $BLUE "   ykman piv certificates import 9a ca-cert.pem"
    echo
    print_status $GREEN "2. Install user certificate to slot 9c (Digital Signature):"
    print_status $BLUE "   ykman piv certificates import 9c user-cert.pem"
    echo
    print_status $GREEN "3. Install user private key to slot 9c:"
    print_status $BLUE "   ykman piv keys import 9c user-key.pem"
    echo
    print_status $GREEN "4. Generate encryption key for slot 9e (Key Management):"
    print_status $BLUE "   ykman piv keys generate 9e -a RSA2048"
    echo
    print_status $GREEN "5. Generate self-signed certificate for slot 9e:"
    print_status $BLUE "   ykman piv certificates generate 9e -s \"CN=$(whoami)@coderedalarmtech.com,O=CodeRed Alarm Tech,C=US\" -a RSA2048"
    echo
    
    print_status $YELLOW "⚠️  Important notes:"
    print_status $YELLOW "  - You'll be prompted for your PIV PIN for each command"
    print_status $YELLOW "  - The default PIV PIN is usually: 123456"
    print_status $YELLOW "  - If you've changed it, use your custom PIN"
    print_status $YELLOW "  - Make sure to run these commands from the certificate directory"
    echo
    
    print_status $BLUE "📁 Certificate files location:"
    print_status $BLUE "  - ca-cert.pem (CA certificate)"
    print_status $BLUE "  - user-cert.pem (User certificate)"
    print_status $BLUE "  - user-key.pem (User private key)"
    print_status $BLUE "  - user-cert.conf (OpenSSL config)"
}

# Verify installation
verify_installation() {
    print_header "✅ Verification Commands"
    
    print_status $BLUE "🔍 After installation, verify with these commands:"
    echo
    print_status $GREEN "1. List all certificates:"
    print_status $BLUE "   ykman piv certificates list"
    echo
    print_status $GREEN "2. Test certificate access:"
    print_status $BLUE "   ykman piv certificates export 9a -"
    print_status $BLUE "   ykman piv certificates export 9c -"
    print_status $BLUE "   ykman piv certificates export 9e -"
    echo
    print_status $GREEN "3. Check PIV info:"
    print_status $BLUE "   ykman piv info"
    echo
}

# Provide next steps
provide_next_steps() {
    print_header "🚀 Next Steps"
    
    print_status $GREEN "✅ Certificates generated successfully!"
    print_status $GREEN "✅ Ready for manual installation to YubiKey"
    echo
    
    print_status $BLUE "🔧 Next steps:"
    print_status $BLUE "  1. Install certificates manually (see instructions above)"
    print_status $BLUE "  2. Verify installation with verification commands"
    print_status $BLUE "  3. Test YubiKey login (lock screen first)"
    print_status $BLUE "  4. Log into iCloud (restore Touch ID)"
    print_status $BLUE "  5. Test logout/login (should be safe now)"
    print_status $BLUE "  6. Set up Virtual MFA for AWS"
    echo
    
    print_status $YELLOW "⚠️  Testing sequence:"
    print_status $YELLOW "  1. Lock screen (Cmd+Ctrl+Q) - test unlock"
    print_status $YELLOW "  2. Test YubiKey unlock"
    print_status $YELLOW "  3. Test password unlock"
    print_status $YELLOW "  4. Only then try logout/login"
    echo
    
    print_status $RED "🚨 Important:"
    print_status $RED "  - Test lock screen first (safer)"
    print_status $RED "  - Verify all login methods work"
    print_status $RED "  - Have recovery plan ready"
    print_status $RED "  - Don't logout until you're confident"
}

# Main function
main() {
    print_status $BLUE "🔐 YubiKey PIV Certificate Generation (Simple)"
    echo
    
    print_status $YELLOW "This script will generate PIV certificates for your YubiKey."
    print_status $YELLOW "You'll install them manually to avoid interactive PIN prompts."
    echo
    
    # Run all steps
    check_prerequisites
    check_piv_status
    generate_piv_certificates
    provide_installation_instructions
    verify_installation
    provide_next_steps
    
    print_header "🎯 Summary"
    
    print_status $GREEN "✅ SUCCESS: PIV certificates generated!"
    print_status $GREEN "✅ Ready for manual installation to YubiKey"
    print_status $GREEN "✅ YubiKey login integration will work after installation"
    echo
    
    print_status $BLUE "💡 What this accomplished:"
    print_status $BLUE "  - Generated CA and user certificates"
    print_status $BLUE "  - Provided manual installation instructions"
    print_status $BLUE "  - Ready for YubiKey login integration"
    print_status $BLUE "  - Will make logout testing much safer"
    echo
    
    print_status $YELLOW "🚀 Ready for next steps:"
    print_status $YELLOW "  - Install certificates manually"
    print_status $YELLOW "  - Test lock screen unlock"
    print_status $YELLOW "  - Log into iCloud"
    print_status $YELLOW "  - Test logout/login"
    print_status $YELLOW "  - Set up AWS MFA"
}

# Run main function
main "$@"
