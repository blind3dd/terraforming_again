# Dev Environment Cost Optimization

## 💰 Cost Savings Summary

### Before Optimization: ~$86-96/month (AWS) + $30-50/month (Azure) = **$116-146/month**

### After Optimization: ~$32-42/month (AWS) + $30-50/month (Azure) = **$62-92/month**

**Total Savings: ~$54/month (~47% reduction)**

---

## 🔧 Optimizations Applied

### 1. EC2 Instance Type Change
- **Before**: `t3.medium` (~$30/month)
- **After**: `t3.micro` (~$7.50/month)
- **Savings**: ~$22.50/month
- **Impact**: Suitable for dev/test workloads

### 2. Disable NAT Gateway
- **Before**: NAT Gateway enabled (~$32/month)
- **After**: Disabled, use Tailscale exit nodes
- **Savings**: ~$32/month
- **Impact**: None - Tailscale provides outbound connectivity

### 3. Keep RDS as-is
- **Current**: `db.t3.micro` (~$13/month)
- **Decision**: Already optimized for dev!
- **Savings**: N/A

### 4. Load Balancer (Future Optimization)
- **Current**: If ALB is deployed (~$21/month)
- **Alternative**: Use NodePort or Ingress
- **Potential Savings**: ~$21/month
- **Note**: Check if ALB is actually needed for dev

---

## 📊 Optimized Dev Environment Cost

```
AWS Resources:
  ✅ VPC & Subnets:              Free
  ✅ Internet Gateway:           Free
  💰 EC2 t3.micro:               $7.50/month
  💰 RDS db.t3.micro:            $13/month
  💰 Route53 hosted zone:        $0.50/month
  💰 S3 (Terraform state):       <$1/month
  💰 DynamoDB (Terraform locks): <$1/month
  💰 Data Transfer:              $10-20/month
  ----------------------------------------
  AWS Total:                     $32-42/month

Azure Resources:
  💰 Jumphost VM:                $30-50/month
  ✅ VNet:                       Minimal
  ----------------------------------------
  Azure Total:                   $30-50/month

Other Services:
  ✅ Tailscale:                  $0/month (Free tier)
  ✅ GitHub Actions:             $0/month (Free tier)
  ----------------------------------------

TOTAL MONTHLY COST:              $62-92/month
```

---

## 🎯 Further Optimization Ideas

### Option 1: NAT Instance Instead of NAT Gateway
If you really need NAT:
- **NAT Gateway**: $32/month
- **t3.nano NAT instance**: ~$3.50/month
- **Savings**: ~$28.50/month
- **Trade-off**: Manual setup, single point of failure

### Option 2: Combine Azure and AWS Workloads
- Move MySQL to Azure (save RDS costs)
- Use single jumphost for both clouds
- **Potential Savings**: ~$13/month

### Option 3: Use AWS Free Tier (First 12 Months)
If your AWS account is <12 months old:
- 750 hours/month t2.micro/t3.micro (EC2)
- 750 hours/month db.t2.micro/db.t3.micro (RDS)
- 5GB S3 storage
- **Savings**: ~$20/month for first year

---

## 🚀 Implementation

The optimizations have been applied to:
```
infrastructure/terraform/environments/dev/terraform.tfvars
```

Changes:
1. `instance_type = "t3.micro"` (was t3.medium)
2. `enable_nat_gateway = false` (was true)

To apply these changes:
```bash
cd infrastructure/terraform/environments/dev
terraform plan    # Review changes
terraform apply   # Apply optimizations
```

---

## ⚠️ Important Notes

### NAT Gateway Disabled
- **Impact**: Private subnet instances won't have direct internet access
- **Solution**: Use Tailscale for outbound connectivity
- **Benefits**: 
  - Zero cost
  - More secure (traffic through Tailscale network)
  - Better for hybrid cloud setup

### Instance Size Reduced
- **t3.micro specs**: 2 vCPU, 1GB RAM
- **Suitable for**:
  - Development workloads
  - Low-traffic applications
  - Testing and experimentation
- **Not suitable for**:
  - High-traffic production apps
  - Memory-intensive workloads
  - CI/CD runners (use t3.small+)

### When to Scale Up
Consider upgrading to test/prod specs when:
- Traffic increases significantly
- Performance testing needed
- Running heavy CI/CD pipelines
- Multi-user development team

---

## 📈 Comparison: Dev vs Test vs Prod

| Component | Dev | Test | Prod |
|-----------|-----|------|------|
| EC2 Instance | 1x t3.micro | 1x t3.small | 2x t3.small (HA) |
| RDS | db.t3.micro | db.t3.small | db.t3.small (Multi-AZ) |
| NAT | None (Tailscale) | NAT Gateway | NAT Gateway x2 (HA) |
| ALB | No | Yes | Yes |
| Monthly Cost | **$40-50** | **$60-80** | **$120-150** |

---

## ✅ Next Steps

1. Review the changes in `terraform.tfvars`
2. Run `terraform plan` to see the cost impact
3. Apply changes with `terraform apply`
4. Monitor costs in AWS Cost Explorer
5. Adjust as needed based on actual usage

**Your dev environment is now cost-optimized!** 🎉

