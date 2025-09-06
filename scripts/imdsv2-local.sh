#!/bin/bash
# Local IMDSv2 Enforcement Script - Embedded in CloudInit
# This script enforces IMDSv2 token authentication locally

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a /var/log/imdsv2-enforcement.log
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a /var/log/imdsv2-enforcement.log
}

# Create secure directory
SECURE_DIR="/opt/imdsv2"
mkdir -p "$SECURE_DIR"
chmod 700 "$SECURE_DIR"
chown root:root "$SECURE_DIR"

log "Starting local IMDSv2 enforcement setup..."

# Function to create iptables rules that block ALL direct metadata access
create_metadata_blocking_rules() {
    log "Creating iptables rules to block direct metadata access..."
    
    # Create the blocking script
    cat > "$SECURE_DIR/block-metadata.sh" << 'EOF'
#!/bin/bash
# Block ALL direct metadata access - Force IMDSv2 token authentication

# Metadata service IP and port
METADATA_IP="169.254.169.254"
METADATA_PORT="80"

# Flush any existing rules for metadata service
iptables -D OUTPUT -d $METADATA_IP -p tcp --dport $METADATA_PORT -j ACCEPT 2>/dev/null || true
iptables -D OUTPUT -d $METADATA_IP -p tcp --dport $METADATA_PORT -j DROP 2>/dev/null || true
iptables -D OUTPUT -d $METADATA_IP -p tcp --dport $METADATA_PORT -j LOG 2>/dev/null || true

# Block ALL direct access to metadata service
# This forces applications to use IMDSv2 tokens
iptables -A OUTPUT -d $METADATA_IP -p tcp --dport $METADATA_PORT -j DROP

# Allow ONLY token endpoint access (PUT requests to /latest/api/token)
# This allows getting IMDSv2 tokens but blocks everything else
iptables -A OUTPUT -d $METADATA_IP -p tcp --dport $METADATA_PORT \
    -m string --string "PUT" --algo bm \
    -m string --string "/latest/api/token" --algo bm \
    -j ACCEPT

# Log all blocked attempts for monitoring
iptables -A OUTPUT -d $METADATA_IP -p tcp --dport $METADATA_PORT \
    -j LOG --log-prefix "BLOCKED_METADATA_ACCESS: " --log-level 4

# Save rules to persist across reboots
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

echo "Metadata access blocking rules applied successfully"
EOF

    chmod +x "$SECURE_DIR/block-metadata.sh"
    
    # Run the blocking script
    "$SECURE_DIR/block-metadata.sh"
    
    log "Direct metadata access blocked - only token-based access allowed"
}

# Function to create secure metadata access wrapper
create_secure_wrapper() {
    log "Creating secure metadata access wrapper..."
    
    cat > "$SECURE_DIR/secure-metadata" << 'EOF'
#!/bin/bash
# Secure metadata access wrapper - REQUIRES IMDSv2 tokens

set -euo pipefail

METADATA_BASE="http://169.254.169.254/latest"
TOKEN_TTL="21600"  # 6 hours

# Function to get IMDSv2 token
get_token() {
    local token
    token=$(curl -s -X PUT "$METADATA_BASE/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: $TOKEN_TTL" \
        --max-time 10)
    
    if [[ -z "$token" ]]; then
        echo "ERROR: Failed to obtain IMDSv2 token" >&2
        exit 1
    fi
    
    echo "$token"
}

# Function to make secure metadata request
secure_request() {
    local path="$1"
    local token="$2"
    
    curl -s -H "X-aws-ec2-metadata-token: $token" \
        "$METADATA_BASE/meta-data/$path" \
        --max-time 10
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <metadata-path>"
        echo "Example: $0 instance-id"
        echo "Example: $0 iam/security-credentials/"
        exit 1
    fi
    
    local path="$1"
    local token
    
    # Get fresh token
    token=$(get_token)
    
    # Make secure request
    secure_request "$path" "$token"
}

main "$@"
EOF

    chmod +x "$SECURE_DIR/secure-metadata"
    chown root:root "$SECURE_DIR/secure-metadata"
    
    # Create symlink for easy access
    ln -sf "$SECURE_DIR/secure-metadata" /usr/local/bin/secure-metadata
    
    log "Secure metadata wrapper created at /usr/local/bin/secure-metadata"
}

# Function to create systemd service for persistent enforcement
create_systemd_service() {
    log "Creating systemd service for persistent enforcement..."
    
    cat > /etc/systemd/system/imdsv2-enforcement.service << EOF
[Unit]
Description=IMDSv2 Enforcement Service
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=$SECURE_DIR/block-metadata.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable imdsv2-enforcement.service
    systemctl start imdsv2-enforcement.service
    
    log "IMDSv2 enforcement service created and started"
}

# Function to test the enforcement
test_enforcement() {
    log "Testing IMDSv2 enforcement..."
    
    # Test 1: Direct access should be blocked
    if curl -s --max-time 5 "http://169.254.169.254/latest/meta-data/instance-id" > /dev/null 2>&1; then
        error "FAILED: Direct metadata access is still allowed!"
        return 1
    else
        log "✓ Direct metadata access is blocked"
    fi
    
    # Test 2: Secure wrapper should work
    local instance_id
    instance_id=$(secure-metadata "instance-id" 2>/dev/null || echo "")
    
    if [[ -n "$instance_id" ]]; then
        log "✓ Secure metadata access works: $instance_id"
    else
        error "FAILED: Secure metadata access is not working!"
        return 1
    fi
    
    # Test 3: Token endpoint should work
    local token
    token=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
        --max-time 5)
    
    if [[ -n "$token" ]]; then
        log "✓ Token endpoint is accessible"
    else
        error "FAILED: Token endpoint is not accessible!"
        return 1
    fi
    
    log "All IMDSv2 enforcement tests passed!"
}

# Main execution
main() {
    log "Setting up local IMDSv2 enforcement..."
    
    # Create blocking rules
    create_metadata_blocking_rules
    
    # Create secure wrapper
    create_secure_wrapper
    
    # Create systemd service
    create_systemd_service
    
    # Test enforcement
    test_enforcement
    
    log "Local IMDSv2 enforcement setup completed successfully!"
    log ""
    log "IMPORTANT: Direct metadata access is now BLOCKED"
    log "Use 'secure-metadata <path>' for secure access"
    log "Example: secure-metadata instance-id"
    log "Example: secure-metadata iam/security-credentials/"
    log ""
    log "Monitoring logs: /var/log/messages"
    log "Enforcement logs: /var/log/imdsv2-enforcement.log"
}

# Run main function
main "$@"
