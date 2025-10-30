#!/usr/bin/env bash
# Terraform Cost Estimation Script
# Provides rough cost estimates based on terraform plan output

set -e

echo "💰 Terraform Cost Estimation"
echo "============================"
echo ""

# Check which environment to analyze
ENVIRONMENT="${1:-dev}"
TF_DIR="infrastructure/terraform/environments/${ENVIRONMENT}"

if [ ! -d "$TF_DIR" ]; then
    echo "❌ Environment directory not found: $TF_DIR"
    echo "Usage: $0 [dev|test|prod|shared]"
    exit 1
fi

echo "🔍 Analyzing environment: ${ENVIRONMENT}"
echo "📂 Directory: ${TF_DIR}"
echo ""

# Change to terraform directory
cd "$TF_DIR"

# Run terraform plan and analyze resources
echo "📋 Running terraform plan..."
if ! PLAN_OUTPUT=$(terraform plan -no-color 2>&1); then
    echo "⚠️  Terraform plan had issues, continuing with cost analysis..."
fi

# Count resources to be created
VPC_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_vpc\." || echo "0")
SUBNET_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_subnet\." || echo "0")
NAT_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_nat_gateway\." || echo "0")
IGW_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_internet_gateway\." || echo "0")
EC2_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_instance\." || echo "0")
RDS_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_db_instance\." || echo "0")
ROUTE53_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_route53_zone\." || echo "0")
ROUTE53_RECORD_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_route53_record\." || echo "0")
LB_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_lb\." || echo "0")
EBS_VOLUME_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_ebs_volume\." || echo "0")
S3_BUCKET_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_s3_bucket\." || echo "0")
DYNAMODB_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_dynamodb_table\." || echo "0")

# Extract instance types
INSTANCE_TYPES=$(echo "$PLAN_OUTPUT" | grep "instance_type" | head -10 || echo "")
RDS_TYPES=$(echo "$PLAN_OUTPUT" | grep "instance_class" | head -5 || echo "")
STORAGE_SIZE=$(echo "$PLAN_OUTPUT" | grep "allocated_storage" | head -5 || echo "")

# Clean counts (remove any newlines or extra chars)
VPC_COUNT=$(echo "$VPC_COUNT" | tr -d '\n' | head -1)
SUBNET_COUNT=$(echo "$SUBNET_COUNT" | tr -d '\n' | head -1)
NAT_COUNT=$(echo "$NAT_COUNT" | tr -d '\n' | head -1)
IGW_COUNT=$(echo "$IGW_COUNT" | tr -d '\n' | head -1)
EC2_COUNT=$(echo "$EC2_COUNT" | tr -d '\n' | head -1)
RDS_COUNT=$(echo "$RDS_COUNT" | tr -d '\n' | head -1)
ROUTE53_COUNT=$(echo "$ROUTE53_COUNT" | tr -d '\n' | head -1)
ROUTE53_RECORD_COUNT=$(echo "$ROUTE53_RECORD_COUNT" | tr -d '\n' | head -1)
LB_COUNT=$(echo "$LB_COUNT" | tr -d '\n' | head -1)
EBS_VOLUME_COUNT=$(echo "$EBS_VOLUME_COUNT" | tr -d '\n' | head -1)
S3_BUCKET_COUNT=$(echo "$S3_BUCKET_COUNT" | tr -d '\n' | head -1)
DYNAMODB_COUNT=$(echo "$DYNAMODB_COUNT" | tr -d '\n' | head -1)

echo "📊 Resources to be created:"
echo "  VPCs: $VPC_COUNT (Free)"
echo "  Subnets: $SUBNET_COUNT (Free)"
echo "  NAT Gateways: $NAT_COUNT"
echo "  Internet Gateways: $IGW_COUNT (Free)"
echo "  EC2 Instances: $EC2_COUNT"
echo "  RDS Instances: $RDS_COUNT"
echo "  Route53 Hosted Zones: $ROUTE53_COUNT"
echo "  Route53 Records: $ROUTE53_RECORD_COUNT"
echo "  Load Balancers (ALB/NLB): $LB_COUNT"
echo "  EBS Volumes: $EBS_VOLUME_COUNT"
echo "  S3 Buckets: $S3_BUCKET_COUNT"
echo "  DynamoDB Tables: $DYNAMODB_COUNT"
echo ""

echo "💰 Estimated Monthly Costs:"
echo "============================"

# NAT Gateway costs
NAT_COST=0
if [ "$NAT_COUNT" -gt 0 ]; then
  NAT_COST=$(echo "$NAT_COUNT * 32" | bc)
  echo "  NAT Gateway(s): \$$NAT_COST/month (approx \$32 each + data transfer)"
fi

# EC2 costs (rough estimates)
EC2_COST=0
if echo "$INSTANCE_TYPES" | grep -q "t3.small"; then
  EC2_COST=$(echo "$EC2_COUNT * 15" | bc)
  echo "  EC2 t3.small: \$$EC2_COST/month (approx \$15 each)"
elif echo "$INSTANCE_TYPES" | grep -q "t3.medium"; then
  EC2_COST=$(echo "$EC2_COUNT * 30" | bc)
  echo "  EC2 t3.medium: \$$EC2_COST/month (approx \$30 each)"
fi

# RDS costs
RDS_COST=0
if [ "$RDS_COUNT" -gt 0 ]; then
  # Check for db.t3.micro
  if echo "$PLAN_OUTPUT" | grep -q "db.t3.micro"; then
    RDS_COST=$(echo "$RDS_COUNT * 13" | bc)
    echo "  RDS db.t3.micro: \$$RDS_COST/month (approx \$13 each)"
  fi
fi

# Route53 costs
ROUTE53_COST=0
if [ "$ROUTE53_COUNT" -gt 0 ]; then
  ROUTE53_COST=$(echo "scale=2; $ROUTE53_COUNT * 0.50" | bc)
  echo "  Route53 hosted zone(s): \$$ROUTE53_COST/month (approx \$0.50 each)"
fi

# Route53 records
ROUTE53_RECORD_COST=0
if [ "$ROUTE53_RECORD_COUNT" -gt 0 ]; then
  # First 1M queries free, then $0.40 per million
  echo "  Route53 records: ${ROUTE53_RECORD_COUNT} (minimal cost, query-based)"
fi

# Load Balancer costs
LB_COST=0
if [ "$LB_COUNT" -gt 0 ]; then
  LB_COST=$(echo "$LB_COUNT * 16" | bc)
  echo "  Application Load Balancer(s): \$$LB_COST/month (approx \$16 each + LCU charges)"
fi

# EBS Volume costs
EBS_COST=0
if [ "$EBS_VOLUME_COUNT" -gt 0 ]; then
  # Assume 50GB gp3 volumes at $0.08/GB/month
  EBS_COST=$(echo "$EBS_VOLUME_COUNT * 4" | bc)
  echo "  EBS Volumes: \$$EBS_COST/month (approx \$4 for 50GB gp3 each)"
fi

# S3 costs
if [ "$S3_BUCKET_COUNT" -gt 0 ]; then
  echo "  S3 Buckets: ${S3_BUCKET_COUNT} (cost depends on storage + requests)"
fi

# DynamoDB costs
DYNAMODB_COST=0
if [ "$DYNAMODB_COUNT" -gt 0 ]; then
  # Assume on-demand pricing, minimal usage
  DYNAMODB_COST=$(echo "$DYNAMODB_COUNT * 1" | bc)
  echo "  DynamoDB Tables: \$$DYNAMODB_COST/month (approx \$1 each for low usage)"
fi

# Data transfer (rough estimate)
DATA_COST="10-30"
echo "  Data Transfer: \$$DATA_COST/month (varies by usage)"
echo ""

# Tailscale costs (if using)
echo "🔵 Tailscale VPN:"
echo "  - Free tier: Up to 3 users, 100 devices"
echo "  - Personal Pro: \$5/user/month (unlimited devices)"
echo "  - Team: \$6/user/month (minimum 5 users)"
echo ""

TOTAL=$(echo "$NAT_COST + $EC2_COST + $RDS_COST + $ROUTE53_COST + $LB_COST + $EBS_COST + $DYNAMODB_COST" | bc)
TOTAL_MAX=$(echo "$TOTAL + 30" | bc)
echo "📊 Total Estimated Monthly Cost (AWS only): \$$TOTAL - \$$TOTAL_MAX"
echo ""
echo "⚠️  Note: These are rough estimates. Actual costs may vary based on:"
echo "  - Data transfer volumes"
echo "  - Region pricing differences"
echo "  - Reserved instance savings (if applicable)"
echo "  - Free tier eligibility (new AWS accounts)"
echo ""
echo "💡 Cost Optimization Tips:"
echo "  - Use NAT Gateway only if needed for private subnets"
echo "  - Consider smaller instance types for test/dev"
echo "  - Enable RDS automated backups only if needed"
echo "  - Monitor data transfer costs"

