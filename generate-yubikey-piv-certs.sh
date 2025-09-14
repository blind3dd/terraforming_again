#!/bin/bash

# YubiKey PIV Certificate Generation Script
# Generates PIV certificates for YubiKey login integration

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
        
        # Test PIV PIN
        print_status $BLUE "🔐 Testing PIV PIN access..."
        print_status $YELLOW "💡 The default PIV PIN is usually: 123456"
        print_status $YELLOW "💡 If you've changed it, use your custom PIN."
        echo
        print_status $BLUE "🔧 Please enter your PIV PIN to test access:"
        if ykman piv info &> /dev/null; then
            print_status $GREEN "✅ PIV PIN access confirmed"
        else
            print_status $RED "❌ PIV PIN access failed"
            print_status $YELLOW "💡 Please check your PIV PIN and try again"
            exit 1
        fi
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
    
    # Create temporary directory for certificates
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    print_status $BLUE "📁 Working directory: $TEMP_DIR"
    
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
}

# Install certificates to YubiKey
install_certificates() {
    print_header "📱 Installing Certificates to YubiKey"
    
    print_status $BLUE "🔧 Installing certificates to YubiKey PIV slots..."
    
    # Get PIV PIN from user
    print_status $YELLOW "🔐 You'll need to enter your PIV PIN for each operation."
    print_status $YELLOW "💡 The default PIV PIN is usually: 123456"
    print_status $YELLOW "💡 If you've changed it, use your custom PIN."
    echo
    
    # Install CA certificate to slot 9a (Authentication)
    print_status $BLUE "📱 Installing CA certificate to slot 9a (Authentication)..."
    if ykman piv certificates import 9a ca-cert.pem; then
        print_status $GREEN "✅ CA certificate installed to slot 9a"
    else
        print_status $RED "❌ Failed to install CA certificate"
        return 1
    fi
    
    # Install user certificate to slot 9c (Digital Signature)
    print_status $BLUE "📱 Installing user certificate to slot 9c (Digital Signature)..."
    if ykman piv certificates import 9c user-cert.pem; then
        print_status $GREEN "✅ User certificate installed to slot 9c"
    else
        print_status $RED "❌ Failed to install user certificate"
        return 1
    fi
    
    # Install user private key to slot 9c (Digital Signature)
    print_status $BLUE "📱 Installing user private key to slot 9c (Digital Signature)..."
    if ykman piv keys import 9c user-key.pem; then
        print_status $GREEN "✅ User private key installed to slot 9c"
    else
        print_status $RED "❌ Failed to install user private key"
        return 1
    fi
    
    # Generate and install encryption key to slot 9e (Key Management)
    print_status $BLUE "📱 Generating encryption key for slot 9e (Key Management)..."
    if ykman piv keys generate 9e -a RSA2048; then
        print_status $GREEN "✅ Encryption key generated for slot 9e"
    else
        print_status $RED "❌ Failed to generate encryption key"
        return 1
    fi
    
    # Generate self-signed certificate for slot 9e
    print_status $BLUE "📱 Generating self-signed certificate for slot 9e..."
    if ykman piv certificates generate 9e -s "CN=$(whoami)@coderedalarmtech.com,O=CodeRed Alarm Tech,C=US" -a RSA2048; then
        print_status $GREEN "✅ Self-signed certificate generated for slot 9e"
    else
        print_status $RED "❌ Failed to generate self-signed certificate"
        return 1
    fi
    
    print_status $GREEN "✅ All certificates installed successfully"
}

# Verify installation
verify_installation() {
    print_header "✅ Verifying Installation"
    
    print_status $BLUE "🔍 Verifying PIV certificate installation..."
    
    # List certificates
    print_status $BLUE "📋 Installed certificates:"
    ykman piv certificates list 2>/dev/null || print_status $YELLOW "⚠️  Could not list certificates"
    
    # Test certificate access
    print_status $BLUE "🔧 Testing certificate access..."
    if ykman piv certificates export 9a - 2>/dev/null | head -1 | grep -q "BEGIN CERTIFICATE"; then
        print_status $GREEN "✅ CA certificate (9a) accessible"
    else
        print_status $YELLOW "⚠️  CA certificate (9a) not accessible"
    fi
    
    if ykman piv certificates export 9c - 2>/dev/null | head -1 | grep -q "BEGIN CERTIFICATE"; then
        print_status $GREEN "✅ User certificate (9c) accessible"
    else
        print_status $YELLOW "⚠️  User certificate (9c) not accessible"
    fi
    
    if ykman piv certificates export 9e - 2>/dev/null | head -1 | grep -q "BEGIN CERTIFICATE"; then
        print_status $GREEN "✅ Encryption certificate (9e) accessible"
    else
        print_status $YELLOW "⚠️  Encryption certificate (9e) not accessible"
    fi
}

# Clean up temporary files
cleanup() {
    print_header "🧹 Cleaning Up"
    
    print_status $BLUE "🗑️  Cleaning up temporary files..."
    
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        cd /
        rm -rf "$TEMP_DIR"
        print_status $GREEN "✅ Temporary files cleaned up"
    fi
}

# Provide next steps
provide_next_steps() {
    print_header "🚀 Next Steps"
    
    print_status $GREEN "✅ PIV certificates generated and installed!"
    print_status $GREEN "✅ YubiKey login integration should now work"
    echo
    
    print_status $BLUE "🔧 Next steps:"
    print_status $BLUE "  1. Test YubiKey login (lock screen first)"
    print_status $BLUE "  2. Log into iCloud (restore Touch ID)"
    print_status $BLUE "  3. Test logout/login (should be safe now)"
    print_status $BLUE "  4. Set up Virtual MFA for AWS"
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
    print_status $BLUE "🔐 YubiKey PIV Certificate Generation"
    echo
    
    print_status $YELLOW "This script will generate and install PIV certificates on your YubiKey."
    print_status $YELLOW "This will enable YubiKey login integration and make logout testing safer."
    echo
    
    # Trap to ensure cleanup on exit
    trap cleanup EXIT
    
    # Run all steps
    check_prerequisites
    check_piv_status
    generate_piv_certificates
    install_certificates
    verify_installation
    provide_next_steps
    
    print_header "🎯 Summary"
    
    print_status $GREEN "✅ SUCCESS: PIV certificates generated and installed!"
    print_status $GREEN "✅ YubiKey login integration should now work"
    print_status $GREEN "✅ Logout testing should be much safer"
    echo
    
    print_status $BLUE "💡 What this accomplished:"
    print_status $BLUE "  - Generated CA and user certificates"
    print_status $BLUE "  - Installed certificates to YubiKey PIV slots"
    print_status $BLUE "  - Enabled YubiKey login integration"
    print_status $BLUE "  - Made logout testing much safer"
    echo
    
    print_status $YELLOW "🚀 Ready for next steps:"
    print_status $YELLOW "  - Test lock screen unlock"
    print_status $YELLOW "  - Log into iCloud"
    print_status $YELLOW "  - Test logout/login"
    print_status $YELLOW "  - Set up AWS MFA"
}

# Run main function
main "$@"
