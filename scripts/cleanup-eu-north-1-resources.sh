#!/bin/bash
# EU-North-1 Resource Cleanup Script
# This script safely removes unnecessary and risky resources based on forensic analysis

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGION="eu-north-1"
PROFILE="eu-north-1"
DRY_RUN=true  # Set to false to actually delete resources

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

# Check AWS credentials
check_credentials() {
    if ! aws sts get-caller-identity --region "${REGION}" --profile "${PROFILE}" >/dev/null 2>&1; then
        error "AWS credentials not configured or invalid"
    fi
    log "AWS credentials verified"
}

# Analyze current resources
analyze_resources() {
    log "Analyzing current resources in ${REGION}..."
    
    # VPCs
    local vpc_count
    vpc_count=$(aws ec2 describe-vpcs --region "${REGION}" --profile "${PROFILE}" --query 'Vpcs | length(@)' --output text)
    info "Found ${vpc_count} VPC(s)"
    
    # Subnets
    local subnet_count
    subnet_count=$(aws ec2 describe-subnets --region "${REGION}" --profile "${PROFILE}" --query 'Subnets | length(@)' --output text)
    info "Found ${subnet_count} subnet(s)"
    
    # Security Groups
    local sg_count
    sg_count=$(aws ec2 describe-security-groups --region "${REGION}" --profile "${PROFILE}" --query 'SecurityGroups | length(@)' --output text)
    info "Found ${sg_count} security group(s)"
    
    # Instances
    local instance_count
    instance_count=$(aws ec2 describe-instances --region "${REGION}" --profile "${PROFILE}" --query 'Reservations[].Instances | length(@)' --output text)
    info "Found ${instance_count} instance(s)"
    
    # Internet Gateways
    local igw_count
    igw_count=$(aws ec2 describe-internet-gateways --region "${REGION}" --profile "${PROFILE}" --query 'InternetGateways | length(@)' --output text)
    info "Found ${igw_count} internet gateway(s)"
    
    # NAT Gateways
    local nat_count
    nat_count=$(aws ec2 describe-nat-gateways --region "${REGION}" --profile "${PROFILE}" --query 'NatGateways | length(@)' --output text)
    info "Found ${nat_count} NAT gateway(s)"
}

# Check for risky security groups
check_risky_security_groups() {
    log "Checking for risky security groups..."
    
    # Check for security groups with overly permissive rules
    local risky_sgs
    risky_sgs=$(aws ec2 describe-security-groups \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]].GroupId' \
        --output text)
    
    if [[ -n "$risky_sgs" ]]; then
        warn "Found security groups with 0.0.0.0/0 access: $risky_sgs"
        for sg in $risky_sgs; do
            info "Security Group $sg allows access from anywhere (0.0.0.0/0)"
        done
    else
        log "No overly permissive security groups found"
    fi
}

# Check for unused resources
check_unused_resources() {
    log "Checking for unused resources..."
    
    # Check for unused security groups (not default)
    local unused_sgs
    unused_sgs=$(aws ec2 describe-security-groups \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --query 'SecurityGroups[?GroupName!=`default` && length(ReferencedBySecurityGroupRules)==`0`].GroupId' \
        --output text)
    
    if [[ -n "$unused_sgs" ]]; then
        info "Found potentially unused security groups: $unused_sgs"
    fi
    
    # Check for unused internet gateways
    local unused_igws
    unused_igws=$(aws ec2 describe-internet-gateways \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --query 'InternetGateways[?length(Attachments)==`0`].InternetGatewayId' \
        --output text)
    
    if [[ -n "$unused_igws" ]]; then
        info "Found detached internet gateways: $unused_igws"
    fi
}

# Clean up default VPC resources (if safe)
cleanup_default_vpc() {
    log "Analyzing default VPC for cleanup..."
    
    # Get default VPC ID
    local default_vpc_id
    default_vpc_id=$(aws ec2 describe-vpcs \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --query 'Vpcs[?IsDefault==`true`].VpcId' \
        --output text)
    
    if [[ -z "$default_vpc_id" ]]; then
        info "No default VPC found"
        return 0
    fi
    
    info "Found default VPC: $default_vpc_id"
    
    # Check if default VPC has any instances
    local instance_count
    instance_count=$(aws ec2 describe-instances \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --filters "Name=vpc-id,Values=$default_vpc_id" \
        --query 'Reservations[].Instances | length(@)' \
        --output text)
    
    if [[ "$instance_count" -gt 0 ]]; then
        warn "Default VPC has $instance_count instance(s) - skipping cleanup"
        return 0
    fi
    
    # Check for other resources in default VPC
    local nat_count
    nat_count=$(aws ec2 describe-nat-gateways \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --filter "Name=vpc-id,Values=$default_vpc_id" \
        --query 'NatGateways | length(@)' \
        --output text)
    
    if [[ "$nat_count" -gt 0 ]]; then
        warn "Default VPC has $nat_count NAT gateway(s) - skipping cleanup"
        return 0
    fi
    
    info "Default VPC appears to be unused - safe for cleanup"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "DRY RUN: Would clean up default VPC resources"
        info "  - Delete default subnets"
        info "  - Detach and delete internet gateway"
        info "  - Delete default security group"
        info "  - Delete default VPC"
    else
        log "Cleaning up default VPC resources..."
        
        # Delete default subnets
        local subnets
        subnets=$(aws ec2 describe-subnets \
            --region "${REGION}" \
            --profile "${PROFILE}" \
            --filters "Name=vpc-id,Values=$default_vpc_id" \
            --query 'Subnets[].SubnetId' \
            --output text)
        
        for subnet in $subnets; do
            log "Deleting subnet: $subnet"
            aws ec2 delete-subnet --region "${REGION}" --profile "${PROFILE}" --subnet-id "$subnet"
        done
        
        # Detach and delete internet gateway
        local igw_id
        igw_id=$(aws ec2 describe-internet-gateways \
            --region "${REGION}" \
            --profile "${PROFILE}" \
            --filters "Name=attachment.vpc-id,Values=$default_vpc_id" \
            --query 'InternetGateways[0].InternetGatewayId' \
            --output text)
        
        if [[ "$igw_id" != "None" && -n "$igw_id" ]]; then
            log "Detaching internet gateway: $igw_id"
            aws ec2 detach-internet-gateway --region "${REGION}" --profile "${PROFILE}" --internet-gateway-id "$igw_id" --vpc-id "$default_vpc_id"
            
            log "Deleting internet gateway: $igw_id"
            aws ec2 delete-internet-gateway --region "${REGION}" --profile "${PROFILE}" --internet-gateway-id "$igw_id"
        fi
        
        # Delete default security group
        local default_sg_id
        default_sg_id=$(aws ec2 describe-security-groups \
            --region "${REGION}" \
            --profile "${PROFILE}" \
            --filters "Name=vpc-id,Values=$default_vpc_id" "Name=group-name,Values=default" \
            --query 'SecurityGroups[0].GroupId' \
            --output text)
        
        if [[ "$default_sg_id" != "None" && -n "$default_sg_id" ]]; then
            log "Deleting default security group: $default_sg_id"
            aws ec2 delete-security-group --region "${REGION}" --profile "${PROFILE}" --group-id "$default_sg_id"
        fi
        
        # Delete default VPC
        log "Deleting default VPC: $default_vpc_id"
        aws ec2 delete-vpc --region "${REGION}" --profile "${PROFILE}" --vpc-id "$default_vpc_id"
        
        log "Default VPC cleanup completed"
    fi
}

# Clean up unused security groups
cleanup_unused_security_groups() {
    log "Cleaning up unused security groups..."
    
    # Get unused security groups (not default, not referenced)
    local unused_sgs
    unused_sgs=$(aws ec2 describe-security-groups \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --query 'SecurityGroups[?GroupName!=`default` && length(ReferencedBySecurityGroupRules)==`0`].GroupId' \
        --output text)
    
    if [[ -z "$unused_sgs" ]]; then
        info "No unused security groups found"
        return 0
    fi
    
    for sg in $unused_sgs; do
        if [[ "$DRY_RUN" == "true" ]]; then
            info "DRY RUN: Would delete unused security group: $sg"
        else
            log "Deleting unused security group: $sg"
            aws ec2 delete-security-group --region "${REGION}" --profile "${PROFILE}" --group-id "$sg"
        fi
    done
}

# Clean up detached internet gateways
cleanup_detached_igws() {
    log "Cleaning up detached internet gateways..."
    
    local detached_igws
    detached_igws=$(aws ec2 describe-internet-gateways \
        --region "${REGION}" \
        --profile "${PROFILE}" \
        --query 'InternetGateways[?length(Attachments)==`0`].InternetGatewayId' \
        --output text)
    
    if [[ -z "$detached_igws" ]]; then
        info "No detached internet gateways found"
        return 0
    fi
    
    for igw in $detached_igws; do
        if [[ "$DRY_RUN" == "true" ]]; then
            info "DRY RUN: Would delete detached internet gateway: $igw"
        else
            log "Deleting detached internet gateway: $igw"
            aws ec2 delete-internet-gateway --region "${REGION}" --profile "${PROFILE}" --internet-gateway-id "$igw"
        fi
    done
}

# Generate cleanup report
generate_cleanup_report() {
    log "Generating cleanup report..."
    
    local report_file="${SCRIPT_DIR}/../backups/cleanup-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# EU-North-1 Resource Cleanup Report

## Summary
- **Date**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Region**: ${REGION}
- **Profile**: ${PROFILE}
- **Mode**: $([ "$DRY_RUN" == "true" ] && echo "DRY RUN" || echo "EXECUTION")

## Current Resources
$(analyze_resources 2>&1)

## Security Analysis
$(check_risky_security_groups 2>&1)

## Unused Resources
$(check_unused_resources 2>&1)

## Cleanup Actions
$([ "$DRY_RUN" == "true" ] && echo "DRY RUN MODE - No actual deletions performed" || echo "EXECUTION MODE - Resources were deleted")

## Recommendations
1. **Default VPC**: Consider removing if unused
2. **Security Groups**: Remove unused groups
3. **Internet Gateways**: Remove detached gateways
4. **Monitoring**: Set up CloudTrail and Config for ongoing monitoring

## Security Best Practices
1. Use least privilege security groups
2. Avoid 0.0.0.0/0 CIDR blocks
3. Regular resource audits
4. Implement resource tagging
5. Enable VPC Flow Logs

EOF
    
    log "Cleanup report generated: $report_file"
}

# Main function
main() {
    log "Starting EU-North-1 resource cleanup..."
    log "Region: ${REGION}"
    log "Profile: ${PROFILE}"
    log "Mode: $([ "$DRY_RUN" == "true" ] && echo "DRY RUN" || echo "EXECUTION")"
    
    # Check credentials
    check_credentials
    
    # Analyze resources
    analyze_resources
    
    # Check for risks
    check_risky_security_groups
    check_unused_resources
    
    # Perform cleanup
    cleanup_default_vpc
    cleanup_unused_security_groups
    cleanup_detached_igws
    
    # Generate report
    generate_cleanup_report
    
    log "Resource cleanup completed!"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "This was a DRY RUN - no resources were actually deleted"
        info "To execute the cleanup, run: DRY_RUN=false $0"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --execute)
            DRY_RUN=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--execute|--dry-run]"
            echo "  --execute   Actually delete resources (default: dry-run)"
            echo "  --dry-run   Show what would be deleted (default)"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Run main function
main "$@"
