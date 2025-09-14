#!/bin/bash
# EC2-Only Resource Audit Script
# This script audits resources using only EC2 permissions (following least privilege principle)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/../backups/ec2-audit"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REGION="eu-north-1"
PROFILE="eu-north-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Create backup directory structure
create_backup_structure() {
    log "Creating EC2 audit backup directory structure..."
    
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/ec2"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/analysis"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/metadata"
    
    # Create metadata file
    cat > "${BACKUP_DIR}/${TIMESTAMP}/metadata/audit_info.json" << EOF
{
  "audit_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "region": "${REGION}",
  "profile": "${PROFILE}",
  "account_id": "$(aws sts get-caller-identity --region ${REGION} --profile ${PROFILE} --query 'Account' --output text)",
  "audit_type": "ec2_only_audit",
  "purpose": "security_audit_with_limited_permissions",
  "permissions": "EC2 only (following least privilege principle)"
}
EOF
}

# Audit EC2 resources (with available permissions)
audit_ec2_resources() {
    log "Auditing EC2 resources with available permissions..."
    
    # VPCs
    log "Backing up VPCs..."
    aws ec2 describe-vpcs --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/vpcs.json" 2>/dev/null || {
        warn "Failed to backup VPCs"
    }
    
    # Subnets
    log "Backing up subnets..."
    aws ec2 describe-subnets --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/subnets.json" 2>/dev/null || {
        warn "Failed to backup subnets"
    }
    
    # Security Groups
    log "Backing up security groups..."
    aws ec2 describe-security-groups --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/security_groups.json" 2>/dev/null || {
        warn "Failed to backup security groups"
    }
    
    # Instances
    log "Backing up instances..."
    aws ec2 describe-instances --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/instances.json" 2>/dev/null || {
        warn "Failed to backup instances"
    }
    
    # Internet Gateways
    log "Backing up internet gateways..."
    aws ec2 describe-internet-gateways --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/internet_gateways.json" 2>/dev/null || {
        warn "Failed to backup internet gateways"
    }
    
    # NAT Gateways
    log "Backing up NAT gateways..."
    aws ec2 describe-nat-gateways --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/nat_gateways.json" 2>/dev/null || {
        warn "Failed to backup NAT gateways"
    }
    
    # Route Tables
    log "Backing up route tables..."
    aws ec2 describe-route-tables --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/route_tables.json" 2>/dev/null || {
        warn "Failed to backup route tables"
    }
    
    # Key Pairs
    log "Backing up key pairs..."
    aws ec2 describe-key-pairs --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/key_pairs.json" 2>/dev/null || {
        warn "Failed to backup key pairs"
    }
    
    # AMIs
    log "Backing up AMIs..."
    aws ec2 describe-images --region "${REGION}" --profile "${PROFILE}" --owners self --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/amis.json" 2>/dev/null || {
        warn "Failed to backup AMIs"
    }
    
    # Volumes
    log "Backing up volumes..."
    aws ec2 describe-volumes --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/volumes.json" 2>/dev/null || {
        warn "Failed to backup volumes"
    }
    
    # Snapshots
    log "Backing up snapshots..."
    aws ec2 describe-snapshots --region "${REGION}" --profile "${PROFILE}" --owner-ids self --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/snapshots.json" 2>/dev/null || {
        warn "Failed to backup snapshots"
    }
    
    # Network ACLs
    log "Backing up network ACLs..."
    aws ec2 describe-network-acls --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/network_acls.json" 2>/dev/null || {
        warn "Failed to backup network ACLs"
    }
    
    # VPC Endpoints
    log "Backing up VPC endpoints..."
    aws ec2 describe-vpc-endpoints --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/vpc_endpoints.json" 2>/dev/null || {
        warn "Failed to backup VPC endpoints"
    }
}

# Analyze security risks
analyze_security_risks() {
    log "Analyzing security risks..."
    
    cat > "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json" << EOF
{
  "analysis_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "risks_found": []
}
EOF
    
    # Check for overly permissive security groups
    local risky_sgs
    risky_sgs=$(jq -r '.SecurityGroups[] | select(.IpPermissions[]?.IpRanges[]?.CidrIp == "0.0.0.0/0") | .GroupId' "${BACKUP_DIR}/${TIMESTAMP}/ec2/security_groups.json" 2>/dev/null || echo "")
    
    if [[ -n "$risky_sgs" ]]; then
        warn "Found security groups with 0.0.0.0/0 access: $risky_sgs"
        jq '.risks_found += [{"type": "overly_permissive_security_group", "details": "Security groups allow access from anywhere (0.0.0.0/0)", "resources": "'"$risky_sgs"'"}]' "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json" > "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json.tmp" && mv "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json.tmp" "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json"
    fi
    
    # Check for instances with public IPs
    local public_instances
    public_instances=$(jq -r '.Reservations[].Instances[] | select(.PublicIpAddress != null) | .InstanceId' "${BACKUP_DIR}/${TIMESTAMP}/ec2/instances.json" 2>/dev/null || echo "")
    
    if [[ -n "$public_instances" ]]; then
        warn "Found instances with public IPs: $public_instances"
        jq '.risks_found += [{"type": "public_instance", "details": "Instances have public IP addresses", "resources": "'"$public_instances"'"}]' "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json" > "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json.tmp" && mv "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json.tmp" "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json"
    fi
    
    # Check for default VPC usage
    local default_vpc
    default_vpc=$(jq -r '.Vpcs[] | select(.IsDefault == true) | .VpcId' "${BACKUP_DIR}/${TIMESTAMP}/ec2/vpcs.json" 2>/dev/null || echo "")
    
    if [[ -n "$default_vpc" ]]; then
        warn "Found default VPC in use: $default_vpc"
        jq '.risks_found += [{"type": "default_vpc_usage", "details": "Default VPC is being used (not recommended for production)", "resources": "'"$default_vpc"'"}]' "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json" > "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json.tmp" && mv "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json.tmp" "${BACKUP_DIR}/${TIMESTAMP}/analysis/security_risks.json"
    fi
}

# Analyze unused resources
analyze_unused_resources() {
    log "Analyzing unused resources..."
    
    cat > "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json" << EOF
{
  "analysis_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "unused_resources": []
}
EOF
    
    # Check for unused security groups (not default, not referenced)
    local unused_sgs
    unused_sgs=$(jq -r '.SecurityGroups[] | select(.GroupName != "default" and (.ReferencedBySecurityGroupRules | length) == 0) | .GroupId' "${BACKUP_DIR}/${TIMESTAMP}/ec2/security_groups.json" 2>/dev/null || echo "")
    
    if [[ -n "$unused_sgs" ]]; then
        info "Found unused security groups: $unused_sgs"
        jq '.unused_resources += [{"type": "unused_security_group", "details": "Security groups not referenced by any rules", "resources": "'"$unused_sgs"'"}]' "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json" > "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json.tmp" && mv "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json.tmp" "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json"
    fi
    
    # Check for detached internet gateways
    local detached_igws
    detached_igws=$(jq -r '.InternetGateways[] | select(.Attachments | length == 0) | .InternetGatewayId' "${BACKUP_DIR}/${TIMESTAMP}/ec2/internet_gateways.json" 2>/dev/null || echo "")
    
    if [[ -n "$detached_igws" ]]; then
        info "Found detached internet gateways: $detached_igws"
        jq '.unused_resources += [{"type": "detached_internet_gateway", "details": "Internet gateways not attached to any VPC", "resources": "'"$detached_igws"'"}]' "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json" > "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json.tmp" && mv "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json.tmp" "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json"
    fi
    
    # Check for unused volumes
    local unused_volumes
    unused_volumes=$(jq -r '.Volumes[] | select(.State == "available" and (.Attachments | length) == 0) | .VolumeId' "${BACKUP_DIR}/${TIMESTAMP}/ec2/volumes.json" 2>/dev/null || echo "")
    
    if [[ -n "$unused_volumes" ]]; then
        info "Found unused volumes: $unused_volumes"
        jq '.unused_resources += [{"type": "unused_volume", "details": "EBS volumes not attached to any instance", "resources": "'"$unused_volumes"'"}]' "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json" > "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json.tmp" && mv "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json.tmp" "${BACKUP_DIR}/${TIMESTAMP}/analysis/unused_resources.json"
    fi
}

# Create analysis report
create_analysis_report() {
    log "Creating analysis report..."
    
    cat > "${BACKUP_DIR}/${TIMESTAMP}/analysis/EC2_AUDIT_REPORT.md" << 'EOF'
# EC2-Only Resource Audit Report

## Executive Summary
This audit was conducted using only EC2 permissions, following the principle of least privilege. The audit focuses on network and compute resources that can be accessed with limited permissions.

## Security Findings

### High Priority Issues
- Review security groups with 0.0.0.0/0 access
- Check instances with public IP addresses
- Evaluate default VPC usage

### Medium Priority Issues
- Remove unused security groups
- Clean up detached internet gateways
- Delete unused EBS volumes

### Low Priority Issues
- Review unused snapshots
- Check for orphaned network ACLs

## Resource Summary
- **VPCs**: Check for default VPC usage
- **Subnets**: Verify subnet configurations
- **Security Groups**: Review access rules
- **Instances**: Check for public exposure
- **Volumes**: Identify unused storage
- **Snapshots**: Review backup retention

## Recommendations

### Immediate Actions
1. **Restrict security group access** - Remove 0.0.0.0/0 rules
2. **Review public instances** - Ensure they need public access
3. **Clean up unused resources** - Reduce cost and attack surface

### Security Best Practices
1. **Use custom VPCs** - Avoid default VPC for production
2. **Implement least privilege** - Restrict access to minimum required
3. **Regular audits** - Monthly resource reviews
4. **Resource tagging** - Better resource management

## Limitations
This audit is limited to EC2 resources due to intentional permission restrictions. For comprehensive security analysis, additional permissions would be required for:
- S3 buckets
- IAM policies
- SSM parameters
- CloudFormation stacks
- CloudWatch logs

## Next Steps
1. Review findings with security team
2. Prioritize high-risk items
3. Create remediation plan
4. Implement monitoring
5. Schedule regular audits
EOF
}

# Create analysis scripts
create_analysis_scripts() {
    log "Creating analysis scripts..."
    
    # Security analysis script
    cat > "${BACKUP_DIR}/${TIMESTAMP}/analyze_security.sh" << 'EOF'
#!/bin/bash
# Security Analysis Script

echo "=== EC2 Security Analysis ==="
echo "Date: $(date)"
echo

echo "Security Groups with Open Access:"
jq -r '.SecurityGroups[] | select(.IpPermissions[]?.IpRanges[]?.CidrIp == "0.0.0.0/0") | "\(.GroupId): \(.GroupName)"' ec2/security_groups.json 2>/dev/null || echo "No overly permissive security groups"

echo
echo "Instances with Public IPs:"
jq -r '.Reservations[].Instances[] | select(.PublicIpAddress != null) | "\(.InstanceId): \(.PublicIpAddress)"' ec2/instances.json 2>/dev/null || echo "No instances with public IPs"

echo
echo "Default VPC Usage:"
jq -r '.Vpcs[] | select(.IsDefault == true) | "\(.VpcId): \(.CidrBlock)"' ec2/vpcs.json 2>/dev/null || echo "No default VPC found"

echo
echo "Detached Internet Gateways:"
jq -r '.InternetGateways[] | select(.Attachments | length == 0) | .InternetGatewayId' ec2/internet_gateways.json 2>/dev/null || echo "No detached internet gateways"
EOF
    
    chmod +x "${BACKUP_DIR}/${TIMESTAMP}/analyze_security.sh"
    
    # Resource summary script
    cat > "${BACKUP_DIR}/${TIMESTAMP}/resource_summary.sh" << 'EOF'
#!/bin/bash
# Resource Summary Script

echo "=== EC2 Resource Summary ==="
echo "Date: $(date)"
echo

echo "VPCs:"
jq -r '.Vpcs | length' ec2/vpcs.json 2>/dev/null || echo "0"

echo "Subnets:"
jq -r '.Subnets | length' ec2/subnets.json 2>/dev/null || echo "0"

echo "Security Groups:"
jq -r '.SecurityGroups | length' ec2/security_groups.json 2>/dev/null || echo "0"

echo "Instances:"
jq -r '.Reservations[].Instances | length' ec2/instances.json 2>/dev/null || echo "0"

echo "Volumes:"
jq -r '.Volumes | length' ec2/volumes.json 2>/dev/null || echo "0"

echo "Snapshots:"
jq -r '.Snapshots | length' ec2/snapshots.json 2>/dev/null || echo "0"

echo "Internet Gateways:"
jq -r '.InternetGateways | length' ec2/internet_gateways.json 2>/dev/null || echo "0"

echo "NAT Gateways:"
jq -r '.NatGateways | length' ec2/nat_gateways.json 2>/dev/null || echo "0"
EOF
    
    chmod +x "${BACKUP_DIR}/${TIMESTAMP}/resource_summary.sh"
}

# Create backup archive
create_backup_archive() {
    log "Creating backup archive..."
    
    local archive_name="ec2-audit-${TIMESTAMP}.tar.gz"
    
    cd "${BACKUP_DIR}"
    tar -czf "${archive_name}" "${TIMESTAMP}/"
    
    # Calculate checksums
    sha256sum "${archive_name}" > "${archive_name}.sha256"
    md5sum "${archive_name}" > "${archive_name}.md5"
    
    log "Backup archive created: ${BACKUP_DIR}/${archive_name}"
    log "SHA256: $(cat "${archive_name}.sha256")"
    log "MD5: $(cat "${archive_name}.md5")"
}

# Main function
main() {
    log "Starting EC2-only resource audit..."
    log "Region: ${REGION}"
    log "Profile: ${PROFILE}"
    log "Backup Directory: ${BACKUP_DIR}/${TIMESTAMP}"
    log "Note: Using limited EC2 permissions (following least privilege principle)"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
        error "AWS credentials not configured or invalid"
    fi
    
    # Create backup structure
    create_backup_structure
    
    # Audit EC2 resources
    audit_ec2_resources
    
    # Analyze findings
    analyze_security_risks
    analyze_unused_resources
    
    # Create analysis tools
    create_analysis_report
    create_analysis_scripts
    
    # Create archive
    create_backup_archive
    
    log "EC2-only resource audit completed successfully!"
    log "Backup location: ${BACKUP_DIR}/${TIMESTAMP}"
    log "Archive: ${BACKUP_DIR}/ec2-audit-${TIMESTAMP}.tar.gz"
    
    info "To analyze the audit:"
    info "  cd ${BACKUP_DIR}/${TIMESTAMP}"
    info "  ./analyze_security.sh"
    info "  ./resource_summary.sh"
    
    info "Note: This audit is limited to EC2 resources due to intentional permission restrictions."
    info "This follows security best practices by using least privilege access."
}

# Run main function
main "$@"
