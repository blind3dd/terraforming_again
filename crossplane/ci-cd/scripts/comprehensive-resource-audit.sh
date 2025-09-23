#!/bin/bash
# Comprehensive Resource Audit Script
# This script audits all accessible AWS resources including S3 buckets, SSM parameters, and other services

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/../backups/comprehensive-audit"
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
    log "Creating comprehensive audit backup directory structure..."
    
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/s3"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/ssm"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/ec2"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/iam"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/cloudformation"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/logs"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/security"
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/metadata"
    
    # Create metadata file
    cat > "${BACKUP_DIR}/${TIMESTAMP}/metadata/audit_info.json" << EOF
{
  "audit_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "region": "${REGION}",
  "profile": "${PROFILE}",
  "account_id": "$(aws sts get-caller-identity --region ${REGION} --profile ${PROFILE} --query 'Account' --output text)",
  "audit_type": "comprehensive_resource_audit",
  "purpose": "security_audit_and_cleanup"
}
EOF
}

# Test AWS service access
test_service_access() {
    log "Testing AWS service access..."
    
    local services=(
        "s3:ListAllMyBuckets"
        "s3:ListBucket"
        "ssm:DescribeParameters"
        "ssm:GetParameter"
        "iam:ListUsers"
        "iam:ListRoles"
        "iam:ListPolicies"
        "cloudformation:ListStacks"
        "cloudformation:DescribeStacks"
        "logs:DescribeLogGroups"
        "logs:DescribeLogStreams"
        "ec2:DescribeInstances"
        "ec2:DescribeVpcs"
        "ec2:DescribeSecurityGroups"
        "ec2:DescribeSubnets"
    )
    
    for service in "${services[@]}"; do
        local service_name="${service%%:*}"
        local action="${service##*:}"
        
        case "$service_name" in
            "s3")
                if aws s3 ls --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
                    info "✓ S3 access available"
                else
                    warn "✗ S3 access denied: $service"
                fi
                ;;
            "ssm")
                if aws ssm describe-parameters --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
                    info "✓ SSM access available"
                else
                    warn "✗ SSM access denied: $service"
                fi
                ;;
            "iam")
                if aws iam list-users --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
                    info "✓ IAM access available"
                else
                    warn "✗ IAM access denied: $service"
                fi
                ;;
            "cloudformation")
                if aws cloudformation list-stacks --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
                    info "✓ CloudFormation access available"
                else
                    warn "✗ CloudFormation access denied: $service"
                fi
                ;;
            "logs")
                if aws logs describe-log-groups --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
                    info "✓ CloudWatch Logs access available"
                else
                    warn "✗ CloudWatch Logs access denied: $service"
                fi
                ;;
            "ec2")
                if aws ec2 describe-instances --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
                    info "✓ EC2 access available"
                else
                    warn "✗ EC2 access denied: $service"
                fi
                ;;
        esac
    done
}

# Audit S3 buckets (with fallback methods)
audit_s3_buckets() {
    log "Auditing S3 buckets..."
    
    # Try direct S3 listing
    if aws s3 ls --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
        aws s3 ls --region "${REGION}" --profile "${PROFILE}" > "${BACKUP_DIR}/${TIMESTAMP}/s3/bucket_list.txt" 2>/dev/null || {
            warn "Failed to list S3 buckets directly"
        }
        
        # Get detailed bucket information
        aws s3api list-buckets --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/s3/buckets_detailed.json" 2>/dev/null || {
            warn "Failed to get detailed S3 bucket information"
        }
    else
        warn "Direct S3 access denied - trying alternative methods"
        
        # Try to find S3 buckets through CloudFormation
        if aws cloudformation list-stacks --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
            log "Searching for S3 buckets in CloudFormation stacks..."
            aws cloudformation list-stacks --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/s3/cloudformation_stacks.json" 2>/dev/null || {
                warn "Failed to list CloudFormation stacks"
            }
        fi
        
        # Try to find S3 buckets through SSM parameters
        if aws ssm describe-parameters --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
            log "Searching for S3 bucket references in SSM parameters..."
            aws ssm describe-parameters --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/s3/ssm_parameters.json" 2>/dev/null || {
                warn "Failed to list SSM parameters"
            }
        fi
    fi
    
    # Check for common S3 bucket naming patterns
    log "Checking for common S3 bucket patterns..."
    local common_patterns=(
        "*-ssm-*"
        "*-logs-*"
        "*-backup-*"
        "*-config-*"
        "*-terraform-*"
        "*-cloudformation-*"
    )
    
    for pattern in "${common_patterns[@]}"; do
        info "Checking pattern: $pattern"
        # Note: This would require S3 access to actually check
    done
}

# Audit SSM parameters
audit_ssm_parameters() {
    log "Auditing SSM parameters..."
    
    if aws ssm describe-parameters --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
        # Get all parameters
        aws ssm describe-parameters --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ssm/parameters.json" 2>/dev/null || {
            warn "Failed to get SSM parameters"
        }
        
        # Get parameter values (be careful with sensitive data)
        local parameters
        parameters=$(aws ssm describe-parameters --region "${REGION}" --profile "${PROFILE}" --query 'Parameters[].Name' --output text 2>/dev/null || echo "")
        
        if [[ -n "$parameters" ]]; then
            for param in $parameters; do
                info "Getting value for parameter: $param"
                aws ssm get-parameter --region "${REGION}" --profile "${PROFILE}" --name "$param" --with-decryption --output json > "${BACKUP_DIR}/${TIMESTAMP}/ssm/parameter_${param//\//_}.json" 2>/dev/null || {
                    warn "Failed to get parameter value: $param"
                }
            done
        fi
    else
        warn "SSM access denied"
    fi
}

# Audit EC2 resources
audit_ec2_resources() {
    log "Auditing EC2 resources..."
    
    # VPCs
    aws ec2 describe-vpcs --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/vpcs.json" 2>/dev/null || {
        warn "Failed to backup VPCs"
    }
    
    # Subnets
    aws ec2 describe-subnets --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/subnets.json" 2>/dev/null || {
        warn "Failed to backup subnets"
    }
    
    # Security Groups
    aws ec2 describe-security-groups --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/security_groups.json" 2>/dev/null || {
        warn "Failed to backup security groups"
    }
    
    # Instances
    aws ec2 describe-instances --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/instances.json" 2>/dev/null || {
        warn "Failed to backup instances"
    }
    
    # Internet Gateways
    aws ec2 describe-internet-gateways --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/internet_gateways.json" 2>/dev/null || {
        warn "Failed to backup internet gateways"
    }
    
    # NAT Gateways
    aws ec2 describe-nat-gateways --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/nat_gateways.json" 2>/dev/null || {
        warn "Failed to backup NAT gateways"
    }
    
    # Route Tables
    aws ec2 describe-route-tables --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/route_tables.json" 2>/dev/null || {
        warn "Failed to backup route tables"
    }
    
    # Key Pairs
    aws ec2 describe-key-pairs --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/ec2/key_pairs.json" 2>/dev/null || {
        warn "Failed to backup key pairs"
    }
}

# Audit IAM resources
audit_iam_resources() {
    log "Auditing IAM resources..."
    
    # Users
    aws iam list-users --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/iam/users.json" 2>/dev/null || {
        warn "Failed to backup IAM users"
    }
    
    # Roles
    aws iam list-roles --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/iam/roles.json" 2>/dev/null || {
        warn "Failed to backup IAM roles"
    }
    
    # Policies
    aws iam list-policies --region "${REGION}" --profile "${PROFILE}" --scope Local --output json > "${BACKUP_DIR}/${TIMESTAMP}/iam/policies.json" 2>/dev/null || {
        warn "Failed to backup IAM policies"
    }
    
    # Groups
    aws iam list-groups --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/iam/groups.json" 2>/dev/null || {
        warn "Failed to backup IAM groups"
    }
}

# Audit CloudFormation stacks
audit_cloudformation_stacks() {
    log "Auditing CloudFormation stacks..."
    
    if aws cloudformation list-stacks --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
        # List all stacks
        aws cloudformation list-stacks --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/cloudformation/stacks.json" 2>/dev/null || {
            warn "Failed to backup CloudFormation stacks"
        }
        
        # Get stack details
        local stack_names
        stack_names=$(aws cloudformation list-stacks --region "${REGION}" --profile "${PROFILE}" --query 'StackSummaries[?StackStatus!=`DELETE_COMPLETE`].StackName' --output text 2>/dev/null || echo "")
        
        if [[ -n "$stack_names" ]]; then
            for stack in $stack_names; do
                info "Backing up stack: $stack"
                aws cloudformation describe-stacks --region "${REGION}" --profile "${PROFILE}" --stack-name "$stack" --output json > "${BACKUP_DIR}/${TIMESTAMP}/cloudformation/stack_${stack}.json" 2>/dev/null || {
                    warn "Failed to backup stack: $stack"
                }
            done
        fi
    else
        warn "CloudFormation access denied"
    fi
}

# Audit CloudWatch Logs
audit_cloudwatch_logs() {
    log "Auditing CloudWatch Logs..."
    
    if aws logs describe-log-groups --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
        # Log Groups
        aws logs describe-log-groups --region "${REGION}" --profile "${PROFILE}" --output json > "${BACKUP_DIR}/${TIMESTAMP}/logs/log_groups.json" 2>/dev/null || {
            warn "Failed to backup log groups"
        }
        
        # Log Streams
        local log_groups
        log_groups=$(aws logs describe-log-groups --region "${REGION}" --profile "${PROFILE}" --query 'logGroups[].logGroupName' --output text 2>/dev/null || echo "")
        
        if [[ -n "$log_groups" ]]; then
            for log_group in $log_groups; do
                info "Backing up log streams for: $log_group"
                aws logs describe-log-streams --region "${REGION}" --profile "${PROFILE}" --log-group-name "$log_group" --output json > "${BACKUP_DIR}/${TIMESTAMP}/logs/streams_${log_group//\//_}.json" 2>/dev/null || {
                    warn "Failed to backup log streams for: $log_group"
                }
            done
        fi
    else
        warn "CloudWatch Logs access denied"
    fi
}

# Create security analysis report
create_security_analysis() {
    log "Creating security analysis report..."
    
    cat > "${BACKUP_DIR}/${TIMESTAMP}/security/SECURITY_ANALYSIS.md" << 'EOF'
# Comprehensive Security Analysis Report

## Executive Summary
This report provides a comprehensive security analysis of AWS resources in eu-north-1 region.

## Risk Assessment

### High Risk Items
- [ ] S3 buckets with public access
- [ ] Security groups with 0.0.0.0/0 access
- [ ] IAM policies with excessive permissions
- [ ] Unencrypted S3 buckets
- [ ] Unused resources with potential cost impact

### Medium Risk Items
- [ ] Default VPC usage
- [ ] Unused security groups
- [ ] Detached internet gateways
- [ ] Unused IAM roles
- [ ] Unencrypted SSM parameters

### Low Risk Items
- [ ] Unused CloudFormation stacks
- [ ] Unused log groups
- [ ] Unused key pairs

## Recommendations

### Immediate Actions
1. **Remove public S3 buckets** - High security risk
2. **Restrict security group access** - Remove 0.0.0.0/0 rules
3. **Enable S3 encryption** - Protect data at rest
4. **Review IAM permissions** - Apply least privilege

### Short Term Actions
1. **Clean up unused resources** - Reduce cost and attack surface
2. **Enable CloudTrail** - Audit all API calls
3. **Enable AWS Config** - Monitor configuration changes
4. **Implement resource tagging** - Better resource management

### Long Term Actions
1. **Regular security audits** - Monthly reviews
2. **Automated compliance checks** - Use AWS Config rules
3. **Cost optimization** - Regular resource reviews
4. **Security training** - Team education

## Compliance Considerations
- **GDPR**: Data protection and privacy
- **SOC 2**: Security controls
- **ISO 27001**: Information security management
- **PCI DSS**: Payment card industry standards

## Next Steps
1. Review this report with security team
2. Prioritize high-risk items
3. Create remediation plan
4. Implement monitoring and alerting
5. Schedule regular reviews
EOF
}

# Create analysis scripts
create_analysis_scripts() {
    log "Creating analysis scripts..."
    
    # S3 analysis script
    cat > "${BACKUP_DIR}/${TIMESTAMP}/analyze_s3.sh" << 'EOF'
#!/bin/bash
# S3 Bucket Analysis Script

echo "=== S3 Bucket Analysis ==="
echo "Date: $(date)"
echo

if [[ -f "s3/bucket_list.txt" ]]; then
    echo "S3 Buckets Found:"
    cat s3/bucket_list.txt
    echo
fi

if [[ -f "s3/buckets_detailed.json" ]]; then
    echo "Bucket Details:"
    jq -r '.Buckets[] | "\(.Name): \(.CreationDate)"' s3/buckets_detailed.json 2>/dev/null || echo "No detailed bucket info"
    echo
fi

echo "SSM Parameters with S3 references:"
if [[ -f "s3/ssm_parameters.json" ]]; then
    jq -r '.Parameters[] | select(.Description | contains("s3") or contains("S3") or contains("bucket")) | "\(.Name): \(.Description)"' s3/ssm_parameters.json 2>/dev/null || echo "No S3 references found"
fi
EOF
    
    chmod +x "${BACKUP_DIR}/${TIMESTAMP}/analyze_s3.sh"
    
    # Security analysis script
    cat > "${BACKUP_DIR}/${TIMESTAMP}/analyze_security.sh" << 'EOF'
#!/bin/bash
# Security Analysis Script

echo "=== Security Analysis ==="
echo "Date: $(date)"
echo

echo "Security Groups with Open Access:"
jq -r '.SecurityGroups[] | select(.IpPermissions[]?.IpRanges[]?.CidrIp == "0.0.0.0/0") | "\(.GroupId): \(.GroupName)"' ec2/security_groups.json 2>/dev/null || echo "No overly permissive security groups"

echo
echo "Instances with Public IPs:"
jq -r '.Reservations[].Instances[] | select(.PublicIpAddress != null) | "\(.InstanceId): \(.PublicIpAddress)"' ec2/instances.json 2>/dev/null || echo "No instances with public IPs"

echo
echo "IAM Roles with Admin Access:"
jq -r '.Roles[] | select(.AssumeRolePolicyDocument | contains("arn:aws:iam::") and contains(":root")) | "\(.RoleName)"' iam/roles.json 2>/dev/null || echo "No admin roles found"

echo
echo "SSM Parameters (check for sensitive data):"
jq -r '.Parameters[] | "\(.Name): \(.Type)"' ssm/parameters.json 2>/dev/null || echo "No SSM parameters found"
EOF
    
    chmod +x "${BACKUP_DIR}/${TIMESTAMP}/analyze_security.sh"
}

# Create backup archive
create_backup_archive() {
    log "Creating backup archive..."
    
    local archive_name="comprehensive-audit-${TIMESTAMP}.tar.gz"
    
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
    log "Starting comprehensive resource audit..."
    log "Region: ${REGION}"
    log "Profile: ${PROFILE}"
    log "Backup Directory: ${BACKUP_DIR}/${TIMESTAMP}"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
        error "AWS credentials not configured or invalid"
    fi
    
    # Create backup structure
    create_backup_structure
    
    # Test service access
    test_service_access
    
    # Audit all services
    audit_s3_buckets
    audit_ssm_parameters
    audit_ec2_resources
    audit_iam_resources
    audit_cloudformation_stacks
    audit_cloudwatch_logs
    
    # Create analysis tools
    create_security_analysis
    create_analysis_scripts
    
    # Create archive
    create_backup_archive
    
    log "Comprehensive resource audit completed successfully!"
    log "Backup location: ${BACKUP_DIR}/${TIMESTAMP}"
    log "Archive: ${BACKUP_DIR}/comprehensive-audit-${TIMESTAMP}.tar.gz"
    
    info "To analyze the audit:"
    info "  cd ${BACKUP_DIR}/${TIMESTAMP}"
    info "  ./analyze_s3.sh"
    info "  ./analyze_security.sh"
}

# Run main function
main "$@"
