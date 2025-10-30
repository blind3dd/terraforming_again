#!/usr/bin/env bash
# Infrastructure Cost Estimation
# Estimates costs for your entire infrastructure setup

set -e

echo "💰 Infrastructure Cost Estimation"
echo "=================================="
echo ""

echo "🏗️  Current Infrastructure Setup:"
echo "=================================="
echo ""

echo "☁️  AWS Resources (us-east-1):"
echo "  - VPC with public/private subnets (Free)"
echo "  - NAT Gateway x1: ~\$32/month"
echo "  - EC2 instances (Tailscale subnet router):"
echo "    - t3.micro x1: ~\$7.50/month"
echo "  - RDS MySQL instance:"
echo "    - db.t3.micro: ~\$13/month (20GB storage included)"
echo "  - Application Load Balancer: ~\$16/month + LCU charges (~\$5/month)"
echo "  - Route53 hosted zone: ~\$0.50/month"
echo "  - S3 bucket (Terraform state): minimal (<\$1/month)"
echo "  - DynamoDB (Terraform locks): minimal (<\$1/month)"
echo "  - Data transfer: ~\$10-20/month"
echo ""

echo "🔵 Azure Resources:"
echo "  - VM (jumphost with Kerberos/GSSAPI): ~\$30-50/month"
echo "  - VNet and networking: minimal"
echo ""

echo "🔒 Tailscale VPN:"
echo "  - Free tier: Up to 3 users, 100 devices ✅"
echo "  - Personal Pro: \$5/user/month (if >3 users)"
echo ""

echo "💾 GitHub:"
echo "  - GitHub Actions: 2000 min/month free (private repo)"
echo "  - Storage: 500MB free"
echo ""

# Calculate AWS total
AWS_NAT=32
AWS_EC2=7.50
AWS_RDS=13
AWS_ALB=21
AWS_ROUTE53=0.50
AWS_STORAGE=2
AWS_DATA_MIN=10
AWS_DATA_MAX=20

AWS_MIN=$(echo "$AWS_NAT + $AWS_EC2 + $AWS_RDS + $AWS_ALB + $AWS_ROUTE53 + $AWS_STORAGE + $AWS_DATA_MIN" | bc)
AWS_MAX=$(echo "$AWS_NAT + $AWS_EC2 + $AWS_RDS + $AWS_ALB + $AWS_ROUTE53 + $AWS_STORAGE + $AWS_DATA_MAX" | bc)

AZURE_MIN=30
AZURE_MAX=50

TOTAL_MIN=$(echo "$AWS_MIN + $AZURE_MIN" | bc)
TOTAL_MAX=$(echo "$AWS_MAX + $AZURE_MAX" | bc)

echo "📊 Cost Summary:"
echo "================"
echo "  AWS:              \$${AWS_MIN} - \$${AWS_MAX}/month"
echo "  Azure:            \$${AZURE_MIN} - \$${AZURE_MAX}/month"
echo "  Tailscale:        \$0/month (Free tier)"
echo "  GitHub:           \$0/month (Free tier)"
echo "  ----------------------------------------"
echo "  TOTAL:            \$${TOTAL_MIN} - \$${TOTAL_MAX}/month"
echo ""

echo "💡 Cost Breakdown:"
echo "=================="
echo "  Biggest costs:"
echo "    1. Azure VM (jumphost):        ~\$30-50/month"
echo "    2. AWS NAT Gateway:            ~\$32/month"
echo "    3. AWS Load Balancer:          ~\$21/month"
echo "    4. AWS RDS (MySQL):            ~\$13/month"
echo "    5. AWS EC2 (Tailscale):        ~\$7.50/month"
echo "    6. AWS Data Transfer:          ~\$10-20/month"
echo ""

echo "🎯 Cost Optimization Opportunities:"
echo "===================================="
echo "  1. NAT Gateway (\$32/month):"
echo "     - Consider NAT instance instead (~\$3.50/month for t3.nano)"
echo "     - Or use Tailscale exit nodes (no extra cost)"
echo ""
echo "  2. Load Balancer (\$21/month):"
echo "     - Use if you need high availability"
echo "     - Or use EC2 with Elastic IP for simple setups (~\$3.60/month)"
echo ""
echo "  3. RDS (\$13/month):"
echo "     - Current: db.t3.micro with 20GB"
echo "     - Already optimized for dev/test!"
echo ""
echo "  4. Tailscale:"
echo "     - You're on FREE tier (perfect!)"
echo "     - Replaces VPN gateway costs"
echo ""
echo "  5. Reserved Instances:"
echo "     - 1-year commitment: ~30% savings"
echo "     - 3-year commitment: ~60% savings"
echo "     - Only for production/long-term use"
echo ""

echo "🚀 Recommended Setup by Environment:"
echo "====================================="
echo ""
echo "  Dev: \$40-50/month"
echo "    - 1x EC2 t3.micro"
echo "    - 1x RDS db.t3.micro"
echo "    - No NAT (use Tailscale)"
echo "    - No ALB (use NodePort/Ingress)"
echo ""
echo "  Test: \$60-80/month"
echo "    - Same as Dev + ALB for testing"
echo "    - NAT Gateway for prod-like setup"
echo ""
echo "  Prod: \$120-150/month"
echo "    - 2x EC2 t3.small (HA)"
echo "    - 1x RDS db.t3.small (Multi-AZ: ~\$26/month)"
echo "    - 1x ALB + NAT Gateway"
echo "    - Enhanced monitoring"
echo ""

echo "💰 Your Current Estimate: \$${TOTAL_MIN} - \$${TOTAL_MAX}/month"
echo ""
echo "✅ You're in good shape! This is a cost-effective setup."
echo ""

