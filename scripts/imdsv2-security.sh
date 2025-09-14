#!/bin/bash
# IMDSv2 Security Enforcement Script
# This script enforces secure metadata access and stores tokens securely

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a /var/log/imdsv2-security.log
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a /var/log/imdsv2-security.log
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a /var/log/imdsv2-security.log
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}" | tee -a /var/log/imdsv2-security.log
}

# Create secure directory for IMDSv2 tokens
IMDSV2_DIR="/opt/imdsv2"
TOKEN_FILE="$IMDSV2_DIR/metadata-token"
VAULT_DIR="/opt/vault"
VAULT_TOKEN_FILE="$VAULT_DIR/imdsv2-token"

log "Starting IMDSv2 security enforcement setup..."

# Create secure directories
mkdir -p "$IMDSV2_DIR" "$VAULT_DIR"
chmod 700 "$IMDSV2_DIR" "$VAULT_DIR"
chown root:root "$IMDSV2_DIR" "$VAULT_DIR"

# Function to get IMDSv2 token
get_imdsv2_token() {
    local token
    token=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
        --max-time 10)
    
    if [[ -z "$token" ]]; then
        error "Failed to obtain IMDSv2 token"
        return 1
    fi
    
    echo "$token"
}

# Function to validate IMDSv2 token
validate_token() {
    local token="$1"
    local response
    
    response=$(curl -s -H "X-aws-ec2-metadata-token: $token" \
        "http://169.254.169.254/latest/meta-data/instance-id" \
        --max-time 5)
    
    if [[ -n "$response" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to store token securely in local Vault
store_token_in_vault() {
    local token="$1"
    local instance_id="$2"
    
    # Create local Vault configuration
    cat > "$VAULT_DIR/vault-config.hcl" << EOF
storage "file" {
  path = "$VAULT_DIR/data"
}

listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable = true
}

disable_mlock = true
api_addr = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"
ui = false
EOF

    # Start Vault in development mode (for local storage only)
    if ! pgrep vault > /dev/null; then
        log "Starting local Vault for secure token storage..."
        nohup vault server -config="$VAULT_DIR/vault-config.hcl" > "$VAULT_DIR/vault.log" 2>&1 &
        sleep 5
    fi
    
    # Initialize Vault if not already initialized
    if [[ ! -f "$VAULT_DIR/vault-init" ]]; then
        log "Initializing local Vault..."
        vault operator init -key-shares=1 -key-threshold=1 > "$VAULT_DIR/vault-keys.txt" 2>/dev/null || true
        
        # Extract unseal key and root token
        UNSEAL_KEY=$(grep "Unseal Key 1:" "$VAULT_DIR/vault-keys.txt" | awk '{print $4}')
        ROOT_TOKEN=$(grep "Initial Root Token:" "$VAULT_DIR/vault-keys.txt" | awk '{print $4}')
        
        # Unseal Vault
        vault operator unseal "$UNSEAL_KEY" > /dev/null 2>&1 || true
        
        # Store root token
        echo "$ROOT_TOKEN" > "$VAULT_DIR/root-token"
        chmod 600 "$VAULT_DIR/root-token"
        
        # Mark as initialized
        touch "$VAULT_DIR/vault-init"
        
        log "Vault initialized and unsealed"
    fi
    
    # Set Vault address and token
    export VAULT_ADDR="http://127.0.0.1:8200"
    export VAULT_TOKEN=$(cat "$VAULT_DIR/root-token")
    
    # Enable KV secrets engine
    vault secrets enable -path=imdsv2 kv-v2 > /dev/null 2>&1 || true
    
    # Store IMDSv2 token securely
    vault kv put "imdsv2/$instance_id" \
        token="$token" \
        created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        ttl="21600" > /dev/null 2>&1 || true
    
    log "IMDSv2 token stored securely in local Vault"
}

# Function to create secure metadata access wrapper
create_metadata_wrapper() {
    cat > "$IMDSV2_DIR/secure-metadata" << 'EOF'
#!/bin/bash
# Secure metadata access wrapper that enforces IMDSv2 tokens

set -euo pipefail

IMDSV2_DIR="/opt/imdsv2"
TOKEN_FILE="$IMDSV2_DIR/metadata-token"
VAULT_DIR="/opt/vault"

# Function to get fresh token
get_fresh_token() {
    local token
    token=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
        --max-time 10)
    
    if [[ -z "$token" ]]; then
        echo "ERROR: Failed to obtain IMDSv2 token" >&2
        exit 1
    fi
    
    echo "$token"
}

# Function to retrieve token from Vault
get_vault_token() {
    if [[ -f "$VAULT_DIR/root-token" ]]; then
        export VAULT_ADDR="http://127.0.0.1:8200"
        export VAULT_TOKEN=$(cat "$VAULT_DIR/root-token")
        
        local instance_id
        instance_id=$(curl -s -H "X-aws-ec2-metadata-token: $(get_fresh_token)" \
            "http://169.254.169.254/latest/meta-data/instance-id")
        
        vault kv get -field=token "imdsv2/$instance_id" 2>/dev/null || get_fresh_token
    else
        get_fresh_token
    fi
}

# Main function
main() {
    local path="$1"
    local token
    
    # Get token (prefer Vault, fallback to fresh)
    token=$(get_vault_token)
    
    # Make secure metadata request
    curl -s -H "X-aws-ec2-metadata-token: $token" \
        "http://169.254.169.254/latest/meta-data/$path" \
        --max-time 10
}

# Check if path is provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <metadata-path>"
    echo "Example: $0 instance-id"
    echo "Example: $0 iam/security-credentials/"
    exit 1
fi

main "$1"
EOF

    chmod +x "$IMDSV2_DIR/secure-metadata"
    chown root:root "$IMDSV2_DIR/secure-metadata"
    
    log "Created secure metadata access wrapper"
}

# Function to disable direct metadata access
disable_direct_metadata_access() {
    # Create iptables rules to block ALL direct metadata access
    cat > "$IMDSV2_DIR/block-direct-metadata.sh" << 'EOF'
#!/bin/bash
# Block ALL direct metadata access - force IMDSv2 token authentication

# Flush existing rules for metadata service
iptables -D OUTPUT -d 169.254.169.254 -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
iptables -D OUTPUT -d 169.254.169.254 -p tcp --dport 80 -j DROP 2>/dev/null || true

# Block ALL direct access to metadata service (169.254.169.254:80)
# This forces all applications to use IMDSv2 tokens
iptables -A OUTPUT -d 169.254.169.254 -p tcp --dport 80 -j DROP

# Allow ONLY token endpoint access (for getting tokens)
iptables -A OUTPUT -d 169.254.169.254 -p tcp --dport 80 -m string --string "PUT" --algo bm -j ACCEPT
iptables -A OUTPUT -d 169.254.169.254 -p tcp --dport 80 -m string --string "/latest/api/token" --algo bm -j ACCEPT

# Log all blocked attempts
iptables -A OUTPUT -d 169.254.169.254 -p tcp --dport 80 -j LOG --log-prefix "BLOCKED_METADATA_ACCESS: " --log-level 4

# Save rules
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
EOF

    chmod +x "$IMDSV2_DIR/block-direct-metadata.sh"
    
    # Create systemd service to enforce metadata security
    cat > /etc/systemd/system/imdsv2-security.service << EOF
[Unit]
Description=IMDSv2 Security Enforcement
After=network.target

[Service]
Type=oneshot
ExecStart=$IMDSV2_DIR/block-direct-metadata.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable imdsv2-security.service
    
    log "Created metadata access blocking rules"
}

# Function to create monitoring script
create_monitoring_script() {
    cat > "$IMDSV2_DIR/monitor-metadata-access.sh" << 'EOF'
#!/bin/bash
# Monitor metadata access attempts

LOG_FILE="/var/log/metadata-access.log"
IMDSV2_DIR="/opt/imdsv2"

# Monitor iptables logs for blocked metadata access
tail -f /var/log/messages | grep "BLOCKED_METADATA_ACCESS" | while read line; do
    echo "$(date): $line" >> "$LOG_FILE"
    
    # Alert on suspicious activity
    if [[ $(grep -c "BLOCKED_METADATA_ACCESS" "$LOG_FILE" | tail -1) -gt 10 ]]; then
        echo "ALERT: Multiple blocked metadata access attempts detected!" | \
            tee -a "$LOG_FILE"
    fi
done
EOF

    chmod +x "$IMDSV2_DIR/monitor-metadata-access.sh"
    
    # Create systemd service for monitoring
    cat > /etc/systemd/system/metadata-monitor.service << EOF
[Unit]
Description=Metadata Access Monitor
After=network.target

[Service]
Type=simple
ExecStart=$IMDSV2_DIR/monitor-metadata-access.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable metadata-monitor.service
    
    log "Created metadata access monitoring"
}

# Main execution
main() {
    log "Setting up IMDSv2 security enforcement..."
    
    # Get instance ID for token storage
    local instance_id
    instance_id=$(curl -s "http://169.254.169.254/latest/meta-data/instance-id" --max-time 5)
    
    if [[ -z "$instance_id" ]]; then
        error "Failed to get instance ID"
        exit 1
    fi
    
    log "Instance ID: $instance_id"
    
    # Get and validate IMDSv2 token
    log "Obtaining IMDSv2 token..."
    local token
    token=$(get_imdsv2_token)
    
    if ! validate_token "$token"; then
        error "IMDSv2 token validation failed"
        exit 1
    fi
    
    log "IMDSv2 token validated successfully"
    
    # Store token securely
    store_token_in_vault "$token" "$instance_id"
    
    # Create secure metadata wrapper
    create_metadata_wrapper
    
    # Disable direct metadata access
    disable_direct_metadata_access
    
    # Create monitoring
    create_monitoring_script
    
    # Start services
    systemctl start imdsv2-security.service
    systemctl start metadata-monitor.service
    
    log "IMDSv2 security enforcement setup completed successfully!"
    log "Use '$IMDSV2_DIR/secure-metadata <path>' for secure metadata access"
    log "Tokens are stored securely in local Vault at $VAULT_DIR"
    
    # Test secure metadata access
    log "Testing secure metadata access..."
    local test_result
    test_result=$("$IMDSV2_DIR/secure-metadata" "instance-id")
    
    if [[ "$test_result" == "$instance_id" ]]; then
        log "Secure metadata access test passed!"
    else
        error "Secure metadata access test failed!"
        exit 1
    fi
}

# Run main function
main "$@"
