#!/usr/bin/env bash
# Terraform Cost Estimation Script
# Provides rough cost estimates based on terraform plan output

set -e

echo "💰 Terraform Cost Estimation"
echo "============================"
echo ""

# Run terraform plan and analyze resources
echo "📋 Analyzing terraform plan..."
PLAN_OUTPUT=$(terraform plan -no-color 2>&1)

# Count resources to be created
VPC_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_vpc" || echo "0")
SUBNET_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_subnet" || echo "0")
NAT_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_nat_gateway" || echo "0")
IGW_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_internet_gateway" || echo "0")
EC2_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_instance" || echo "0")
RDS_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_db_instance" || echo "0")
ROUTE53_COUNT=$(echo "$PLAN_OUTPUT" | grep -c "aws_route53" || echo "0")

# Extract instance types
INSTANCE_TYPES=$(echo "$PLAN_OUTPUT" | grep "instance_type" | head -5 || echo "")

echo "📊 Resources to be created:"
echo "  VPCs: $VPC_COUNT (Free)"
echo "  Subnets: $SUBNET_COUNT (Free)"
echo "  NAT Gateways: $NAT_COUNT"
echo "  Internet Gateways: $IGW_COUNT (Free)"
echo "  EC2 Instances: $EC2_COUNT"
echo "  RDS Instances: $RDS_COUNT"
echo "  Route53 Records: $ROUTE53_COUNT"
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
  echo "  Route53 hosted zone: \$$ROUTE53_COST/month (approx \$0.50 each)"
fi

# Data transfer (rough estimate)
DATA_COST="5-20"
echo "  Data Transfer: \$$DATA_COST/month (varies by usage)"
echo ""

TOTAL=$(echo "$NAT_COST + $EC2_COST + $RDS_COST + $ROUTE53_COST" | bc)
echo "📊 Total Estimated Monthly Cost: \$$TOTAL - \$$(echo "$TOTAL + 20" | bc)"
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

