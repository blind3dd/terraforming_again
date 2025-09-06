# DHCP and Private FQDN Configuration Guide

## Overview

This guide explains the comprehensive DHCP and private FQDN configuration for proper DNS resolution within the VPC, including Route53 integration and load balancer support.

## DHCP Configuration

### 1. **Enhanced DHCP Options Set**

```hcl
resource "aws_vpc_dhcp_options" "private_fqdn" {
  # Primary domain name for private FQDN resolution
  domain_name = "internal.${var.domain_name}"
  
  # DNS servers for private FQDN resolution
  domain_name_servers = [
    "AmazonProvidedDNS",           # AWS VPC DNS resolver (169.254.169.253)
    "8.8.8.8",                    # Google DNS (backup)
    "8.8.4.4"                     # Google DNS (backup)
  ]
  
  # NTP servers for time synchronization
  ntp_servers = [
    "169.254.169.123",            # AWS NTP server (primary)
    "pool.ntp.org"                # Public NTP server (backup)
  ]
  
  # NetBIOS configuration for Windows compatibility
  netbios_name_servers = [
    "169.254.169.123"             # AWS NTP server (used as placeholder)
  ]
  
  netbios_node_type = 2           # P-node (point-to-point)
}
```

### 2. **DHCP Options Explained**

| Option | Value | Purpose |
|--------|-------|---------|
| `domain_name` | `internal.${var.domain_name}` | Sets the search domain for private FQDNs |
| `domain_name_servers` | `AmazonProvidedDNS, 8.8.8.8, 8.8.4.4` | DNS servers for resolution |
| `ntp_servers` | `169.254.169.123, pool.ntp.org` | Time synchronization servers |
| `netbios_name_servers` | `169.254.169.123` | NetBIOS name resolution |
| `netbios_node_type` | `2` | NetBIOS node type (P-node) |

## Private FQDN Configuration

### 1. **Route53 Private Hosted Zone**

```hcl
resource "aws_route53_zone" "private" {
  name = "internal.${var.domain_name}"

  vpc {
    vpc_id = data.aws_vpc.main.id
  }
}
```

### 2. **Private FQDN Records**

#### **RDS Private FQDN**
```hcl
resource "aws_route53_record" "rds_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "mysql.internal.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.mysql.endpoint]
}
```

#### **Kubernetes API Private FQDN**
```hcl
resource "aws_route53_record" "k8s_api_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "k8s-api.internal.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.kubernetes_control_plane.private_ip]
}
```

#### **Load Balancer Private FQDNs**
```hcl
# ALB Private FQDN
resource "aws_route53_record" "alb_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "alb.internal.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.rds_app_alb.dns_name
    zone_id                = aws_lb.rds_app_alb.zone_id
    evaluate_target_health = true
  }
}

# NLB Private FQDN
resource "aws_route53_record" "nlb_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "nlb.internal.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.rds_app_nlb.dns_name
    zone_id                = aws_lb.rds_app_nlb.zone_id
    evaluate_target_health = true
  }
}
```

## DNS Resolution Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPC DNS Resolution                          │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │   EC2 Instance  │───►│  DHCP Options   │                   │
│  │                 │    │     Set         │                   │
│  └─────────────────┘    └─────────────────┘                   │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │  DNS Query      │───►│  Route53        │                   │
│  │  (Private FQDN) │    │  Private Zone   │                   │
│  └─────────────────┘    └─────────────────┘                   │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │  DNS Resolver   │───►│  VPC Endpoint   │                   │
│  │                 │    │  (Route53)      │                   │
│  └─────────────────┘    └─────────────────┘                   │
│           │                       │                           │
│           ▼                       ▼                           │
│  ┌─────────────────┐    ┌─────────────────┐                   │
│  │  AWS VPC DNS    │───►│  Load Balancer  │                   │
│  │  (169.254.169.253)│    │  (ALB/NLB)      │                   │
│  └─────────────────┘    └─────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

## Private FQDN Examples

### 1. **Service FQDNs**

| Service | Private FQDN | Purpose |
|---------|--------------|---------|
| RDS | `mysql.internal.${var.domain_name}` | Database connection |
| Kubernetes API | `k8s-api.internal.${var.domain_name}` | Kubernetes API access |
| VPN Server | `vpn.internal.${var.domain_name}` | VPN server access |
| Jump Host | `jump.internal.${var.domain_name}` | Bastion host access |
| ALB | `alb.internal.${var.domain_name}` | Application Load Balancer |
| NLB | `nlb.internal.${var.domain_name}` | Network Load Balancer |

### 2. **Kubernetes Worker FQDNs**

| Worker | Private FQDN | Purpose |
|--------|--------------|---------|
| Worker 1 | `k8s-worker-1.internal.${var.domain_name}` | Individual worker access |
| Worker 2 | `k8s-worker-2.internal.${var.domain_name}` | Individual worker access |
| Workers LB | `k8s-workers.internal.${var.domain_name}` | Load balanced access |

## DNS Resolver Configuration

### 1. **VPC Endpoint for Route53**

```hcl
resource "aws_vpc_endpoint" "route53" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.route53"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id, aws_subnet.private_2.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}
```

### 2. **DNS Resolver Endpoint**

```hcl
resource "aws_route53_resolver_endpoint" "private" {
  name      = "private-dns-resolver"
  direction = "INBOUND"

  security_group_ids = [aws_security_group.vpc_endpoint.id]

  ip_address {
    subnet_id = aws_subnet.private.id
  }

  ip_address {
    subnet_id = aws_subnet.private_2.id
  }
}
```

### 3. **DNS Resolver Rule**

```hcl
resource "aws_route53_resolver_rule" "private" {
  domain_name          = "internal.${var.domain_name}"
  name                 = "private-fqdn-rule"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.private.id

  target_ip {
    ip = "169.254.169.253"  # AWS VPC DNS resolver
  }
}
```

## Load Balancer Integration

### 1. **Application Load Balancer (ALB)**

```hcl
# ALB with Route53 integration
resource "aws_lb" "rds_app_alb" {
  name               = "rds-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_2.id]
}

# Route53 record for ALB
resource "aws_route53_record" "rds_app_alb" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "rds-app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.rds_app_alb.dns_name
    zone_id                = aws_lb.rds_app_alb.zone_id
    evaluate_target_health = true
  }
}
```

### 2. **Network Load Balancer (NLB)**

```hcl
# NLB with Route53 integration
resource "aws_lb" "rds_app_nlb" {
  name               = "rds-app-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public.id, aws_subnet.public_2.id]
}

# Route53 record for NLB
resource "aws_route53_record" "rds_app_nlb" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "rds-app-nlb.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.rds_app_nlb.dns_name
    zone_id                = aws_lb.rds_app_nlb.zone_id
    evaluate_target_health = true
  }
}
```

## Security Features

### 1. **WAF Integration**

```hcl
# WAF Web ACL for load balancer protection
resource "aws_wafv2_web_acl" "rds_app" {
  name  = "rds-app-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
  }
}

# WAF Association with ALB
resource "aws_wafv2_web_acl_association" "rds_app_alb" {
  resource_arn = aws_lb.rds_app_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.rds_app.arn
}
```

### 2. **SSL/TLS Certificate**

```hcl
# ACM Certificate for HTTPS
resource "aws_acm_certificate" "rds_app" {
  domain_name       = "rds-app.${var.domain_name}"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.rds-app.${var.domain_name}",
    "rds-app-api.${var.domain_name}",
    "rds-app-admin.${var.domain_name}"
  ]
}
```

## Monitoring and Logging

### 1. **CloudWatch Logs**

```hcl
# CloudWatch Log Group for ALB
resource "aws_cloudwatch_log_group" "rds_app_alb" {
  name              = "/aws/applicationloadbalancer/rds-app-alb"
  retention_in_days = 30
}

# CloudWatch Log Group for NLB
resource "aws_cloudwatch_log_group" "rds_app_nlb" {
  name              = "/aws/networkloadbalancer/rds-app-nlb"
  retention_in_days = 30
}
```

### 2. **CloudWatch Dashboard**

```hcl
# CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "rds_app" {
  dashboard_name = "rds-app-load-balancer"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.rds_app_alb.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS App ALB Metrics"
          period  = 300
        }
      }
    ]
  })
}
```

## Deployment Steps

### 1. **Deploy DHCP Configuration**

```bash
# Deploy DHCP options set
terraform apply -target=aws_vpc_dhcp_options.private_fqdn
terraform apply -target=aws_vpc_dhcp_options_association.private_fqdn
```

### 2. **Deploy Route53 Private Zone**

```bash
# Deploy private hosted zone
terraform apply -target=aws_route53_zone.private
```

### 3. **Deploy Private FQDN Records**

```bash
# Deploy private FQDN records
terraform apply -target=aws_route53_record.rds_private
terraform apply -target=aws_route53_record.k8s_api_private
terraform apply -target=aws_route53_record.vpn_private
terraform apply -target=aws_route53_record.jump_private
```

### 4. **Deploy Load Balancers**

```bash
# Deploy load balancers
terraform apply -target=aws_lb.rds_app_alb
terraform apply -target=aws_lb.rds_app_nlb
```

### 5. **Deploy Route53 Public Records**

```bash
# Deploy public Route53 records
terraform apply -target=aws_route53_record.rds_app_alb
terraform apply -target=aws_route53_record.rds_app_nlb
```

## Verification

### 1. **Check DHCP Configuration**

```bash
# Check DHCP options set
aws ec2 describe-dhcp-options --dhcp-options-ids $(terraform output -raw dhcp_options_id)

# Check VPC association
aws ec2 describe-vpcs --vpc-ids $(terraform output -raw vpc_id)
```

### 2. **Test Private FQDN Resolution**

```bash
# Test private FQDN resolution from EC2 instance
nslookup mysql.internal.${var.domain_name}
nslookup k8s-api.internal.${var.domain_name}
nslookup vpn.internal.${var.domain_name}
nslookup jump.internal.${var.domain_name}
```

### 3. **Test Load Balancer Access**

```bash
# Test ALB access
curl -I http://rds-app.${var.domain_name}
curl -I https://rds-app.${var.domain_name}

# Test NLB access
curl -I http://rds-app-nlb.${var.domain_name}
```

### 4. **Check Route53 Records**

```bash
# Check private hosted zone
aws route53 list-resource-record-sets --hosted-zone-id $(terraform output -raw private_zone_id)

# Check public hosted zone
aws route53 list-resource-record-sets --hosted-zone-id $(terraform output -raw public_zone_id)
```

## Best Practices

### 1. **DNS Configuration**
- **Use Private Hosted Zones**: For internal service discovery
- **Set Appropriate TTLs**: Balance between performance and flexibility
- **Use Alias Records**: For load balancers and AWS services
- **Implement DNS Caching**: For better performance

### 2. **Load Balancer Configuration**
- **Use ALB for HTTP/HTTPS**: Layer 7 load balancing
- **Use NLB for TCP/UDP**: Layer 4 load balancing
- **Enable Health Checks**: For better reliability
- **Implement SSL/TLS**: For secure communication

### 3. **Security**
- **Use WAF**: For application-level protection
- **Enable SSL/TLS**: For encrypted communication
- **Implement Rate Limiting**: For DDoS protection
- **Use Security Groups**: For network-level security

### 4. **Monitoring**
- **Enable Access Logs**: For load balancer monitoring
- **Use CloudWatch**: For metrics and alerting
- **Implement Dashboards**: For operational visibility
- **Set Up Alerts**: For proactive monitoring

## Conclusion

This comprehensive DHCP and private FQDN configuration provides:

✅ **Complete DNS Resolution**: Private FQDNs for all services
✅ **Load Balancer Integration**: ALB and NLB with Route53
✅ **Security Features**: WAF, SSL/TLS, and security groups
✅ **Monitoring**: CloudWatch logs and dashboards
✅ **High Availability**: Multi-AZ deployment
✅ **Scalability**: Auto-scaling and load balancing

The configuration ensures proper DNS resolution within the VPC while providing secure, scalable, and monitored access to all services.
