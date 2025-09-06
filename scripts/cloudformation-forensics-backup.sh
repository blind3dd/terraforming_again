#!/bin/bash
# CloudFormation Forensics Backup Script
# This script creates comprehensive backups of CloudFormation stacks for forensic analysis

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/../backups/cloudformation-forensics"
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
    log "Creating backup directory structure..."
    
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/stacks"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/resources"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/events"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/templates"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/exports"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/metadata"
    
    # Create metadata file
    cat > "${BACKUP_DIR}/${TIMESTAMP}/metadata/backup_info.json" << EOF
{
  "backup_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "region": "${REGION}",
  "profile": "${PROFILE}",
  "account_id": "$(aws sts get-caller-identity --region ${REGION} --profile ${PROFILE} --query 'Account' --output text)",
  "backup_type": "cloudformation_forensics",
  "purpose": "forensic_analysis_and_disaster_recovery"
}
EOF
}

# Backup CloudFormation stacks
backup_cloudformation_stacks() {
    log "Backing up CloudFormation stacks..."
    
    # Get all stack names (including deleted ones for forensics)
    local stack_names
    stack_names=$(aws cloudformation list-stacks \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --query 'StackSummaries[?StackStatus!=`DELETE_COMPLETE`].StackName' \
        --output text 2>/dev/null || echo "")
    
    if [[ -z "$stack_names" ]]; then
        warn "No CloudFormation stacks found or access denied"
        return 0
    fi
    
    for stack_name in $stack_names; do
        log "Backing up stack: $stack_name"
        
        # Backup stack details
        aws cloudformation describe-stacks \
            --region "${REGION}" \
            --profile "${PROFILE}" \
            --stack-name "$stack_name" \
            --output json > "${BACKUP_DIR}/${TIMESTAMP}/stacks/${stack_name}_details.json" 2>/dev/null || {
            warn "Failed to backup stack details for: $stack_name"
            continue
        }
        
        # Backup stack resources
        aws cloudformation describe-stack-resources \
            --region "${REGION}" \
            --profile "${PROFILE}" \
            --stack-name "$stack_name" \
            --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/${stack_name}_resources.json" 2>/dev/null || {
            warn "Failed to backup stack resources for: $stack_name"
        }
        
        # Backup stack events
        aws cloudformation describe-stack-events \
            --region "${REGION}" \
            --profile "${PROFILE}" \
            --stack-name "$stack_name" \
            --output json > "${BACKUP_DIR}/${TIMESTAMP}/events/${stack_name}_events.json" 2>/dev/null || {
            warn "Failed to backup stack events for: $stack_name"
        }
        
        # Backup stack template
        aws cloudformation get-template \
            --region "${REGION}" \
            --profile "${PROFILE}" \
            --stack-name "$stack_name" \
            --output json > "${BACKUP_DIR}/${TIMESTAMP}/templates/${stack_name}_template.json" 2>/dev/null || {
            warn "Failed to backup stack template for: $stack_name"
        }
        
        # Backup stack exports
        aws cloudformation list-exports \
            --region "${REGION}" \
            --profile "${PROFILE}" \
            --output json > "${BACKUP_DIR}/${TIMESTAMP}/exports/${stack_name}_exports.json" 2>/dev/null || {
            warn "Failed to backup stack exports for: $stack_name"
        }
    done
}

# Backup all CloudFormation exports
backup_all_exports() {
    log "Backing up all CloudFormation exports..."
    
    aws cloudformation list-exports \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/exports/all_exports.json" 2>/dev/null || {
        warn "Failed to backup all exports"
    }
}

# Backup VPC and networking resources
backup_networking_resources() {
    log "Backing up VPC and networking resources..."
    
    # VPCs
    aws ec2 describe-vpcs \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/vpcs.json" 2>/dev/null || {
        warn "Failed to backup VPCs"
    }
    
    # Subnets
    aws ec2 describe-subnets \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/subnets.json" 2>/dev/null || {
        warn "Failed to backup subnets"
    }
    
    # Security Groups
    aws ec2 describe-security-groups \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/security_groups.json" 2>/dev/null || {
        warn "Failed to backup security groups"
    }
    
    # Internet Gateways
    aws ec2 describe-internet-gateways \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/internet_gateways.json" 2>/dev/null || {
        warn "Failed to backup internet gateways"
    }
    
    # Route Tables
    aws ec2 describe-route-tables \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/route_tables.json" 2>/dev/null || {
        warn "Failed to backup route tables"
    }
    
    # NAT Gateways
    aws ec2 describe-nat-gateways \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/nat_gateways.json" 2>/dev/null || {
        warn "Failed to backup NAT gateways"
    }
}

# Backup EC2 resources
backup_ec2_resources() {
    log "Backing up EC2 resources..."
    
    # Instances
    aws ec2 describe-instances \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/instances.json" 2>/dev/null || {
        warn "Failed to backup instances"
    }
    
    # Key Pairs
    aws ec2 describe-key-pairs \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/key_pairs.json" 2>/dev/null || {
        warn "Failed to backup key pairs"
    }
    
    # AMIs
    aws ec2 describe-images \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --owners self \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/amis.json" 2>/dev/null || {
        warn "Failed to backup AMIs"
    }
}

# Backup IAM resources
backup_iam_resources() {
    log "Backing up IAM resources..."
    
    # Roles
    aws iam list-roles \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/iam_roles.json" 2>/dev/null || {
        warn "Failed to backup IAM roles"
    }
    
    # Policies
    aws iam list-policies \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --scope Local \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/iam_policies.json" 2>/dev/null || {
        warn "Failed to backup IAM policies"
    }
    
    # Users
    aws iam list-users \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --output json > "${BACKUP_DIR}/${TIMESTAMP}/resources/iam_users.json" 2>/dev/null || {
        warn "Failed to backup IAM users"
    }
}

# Create forensic analysis report
create_forensic_report() {
    log "Creating forensic analysis report..."
    
    cat > "${BACKUP_DIR}/${TIMESTAMP}/FORENSIC_ANALYSIS_REPORT.md" << 'EOF'
# CloudFormation Forensics Analysis Report

## Backup Information
- **Backup Date**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Region**: eu-north-1
- **Purpose**: Forensic Analysis and Disaster Recovery

## Analysis Checklist

### 1. CloudFormation Stacks
- [ ] Review all stack configurations
- [ ] Check for unauthorized changes
- [ ] Verify stack dependencies
- [ ] Analyze stack events timeline

### 2. Security Analysis
- [ ] Review security group rules
- [ ] Check for overly permissive access
- [ ] Verify VPC configurations
- [ ] Analyze network ACLs

### 3. Resource Inventory
- [ ] Document all EC2 instances
- [ ] List all storage volumes
- [ ] Check for orphaned resources
- [ ] Verify resource tagging

### 4. Access Control Review
- [ ] Review IAM roles and policies
- [ ] Check for privilege escalation
- [ ] Verify user permissions
- [ ] Analyze access patterns

### 5. Cost Analysis
- [ ] Identify unused resources
- [ ] Check for cost optimization opportunities
- [ ] Review resource utilization
- [ ] Document potential savings

## Files Structure
```
backups/cloudformation-forensics/TIMESTAMP/
├── stacks/           # Stack configurations
├── resources/        # Resource details
├── events/          # Stack events
├── templates/       # CloudFormation templates
├── exports/         # Stack exports
└── metadata/        # Backup metadata
```

## Forensic Tools
- Use `jq` for JSON analysis
- Use `aws-cli` for additional queries
- Use CloudTrail for access logs
- Use Config for compliance checks

## Security Recommendations
1. Enable CloudTrail logging
2. Enable AWS Config
3. Implement resource tagging
4. Regular security audits
5. Cost monitoring and alerts
EOF
}

# Create analysis scripts
create_analysis_scripts() {
    log "Creating forensic analysis scripts..."
    
    # Stack analysis script
    cat > "${BACKUP_DIR}/${TIMESTAMP}/analyze_stacks.sh" << 'EOF'
#!/bin/bash
# CloudFormation Stack Analysis Script

echo "=== CloudFormation Stack Analysis ==="
echo "Date: $(date)"
echo

echo "Stack Count:"
find stacks/ -name "*_details.json" | wc -l

echo
echo "Stack Names:"
find stacks/ -name "*_details.json" -exec basename {} _details.json \;

echo
echo "Stack Status Summary:"
for file in stacks/*_details.json; do
    if [[ -f "$file" ]]; then
        stack_name=$(basename "$file" _details.json)
        status=$(jq -r '.Stacks[0].StackStatus' "$file" 2>/dev/null || echo "Unknown")
        echo "  $stack_name: $status"
    fi
done

echo
echo "Resource Count by Stack:"
for file in resources/*_resources.json; do
    if [[ -f "$file" ]]; then
        stack_name=$(basename "$file" _resources.json)
        count=$(jq -r '.StackResources | length' "$file" 2>/dev/null || echo "0")
        echo "  $stack_name: $count resources"
    fi
done
EOF
    
    chmod +x "${BACKUP_DIR}/${TIMESTAMP}/analyze_stacks.sh"
    
    # Security analysis script
    cat > "${BACKUP_DIR}/${TIMESTAMP}/analyze_security.sh" << 'EOF'
#!/bin/bash
# Security Analysis Script

echo "=== Security Analysis ==="
echo "Date: $(date)"
echo

echo "Security Groups with Open Access:"
jq -r '.SecurityGroups[] | select(.IpPermissions[]?.IpRanges[]?.CidrIp == "0.0.0.0/0") | "\(.GroupId): \(.GroupName)"' resources/security_groups.json 2>/dev/null || echo "No data"

echo
echo "Instances with Public IPs:"
jq -r '.Reservations[].Instances[] | select(.PublicIpAddress != null) | "\(.InstanceId): \(.PublicIpAddress)"' resources/instances.json 2>/dev/null || echo "No data"

echo
echo "IAM Roles:"
jq -r '.Roles[] | "\(.RoleName): \(.AssumeRolePolicyDocument)"' resources/iam_roles.json 2>/dev/null || echo "No data"
EOF
    
    chmod +x "${BACKUP_DIR}/${TIMESTAMP}/analyze_security.sh"
}

# Create backup archive
create_backup_archive() {
    log "Creating backup archive..."
    
    local archive_name="cloudformation-forensics-${TIMESTAMP}.tar.gz"
    
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
    log "Starting CloudFormation forensics backup..."
    log "Region: ${REGION}"
    log "Profile: ${PROFILE}"
    log "Backup Directory: ${BACKUP_DIR}/${TIMESTAMP}"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
        error "AWS credentials not configured or invalid"
    fi
    
    # Create backup structure
    create_backup_structure
    
    # Backup CloudFormation resources
    backup_cloudformation_stacks
    backup_all_exports
    
    # Backup AWS resources
    backup_networking_resources
    backup_ec2_resources
    backup_iam_resources
    
    # Create analysis tools
    create_forensic_report
    create_analysis_scripts
    
    # Create archive
    create_backup_archive
    
    log "CloudFormation forensics backup completed successfully!"
    log "Backup location: ${BACKUP_DIR}/${TIMESTAMP}"
    log "Archive: ${BACKUP_DIR}/cloudformation-forensics-${TIMESTAMP}.tar.gz"
    
    info "To analyze the backup:"
    info "  cd ${BACKUP_DIR}/${TIMESTAMP}"
    info "  ./analyze_stacks.sh"
    info "  ./analyze_security.sh"
}

# Run main function
main "$@"
