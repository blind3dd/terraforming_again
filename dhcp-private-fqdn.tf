# DHCP Options Set for Private FQDN Resolution
# This file configures DHCP options for proper private FQDN resolution within the VPC

# =============================================================================
# DHCP OPTIONS SET FOR PRIVATE FQDN RESOLUTION
# =============================================================================

# Enhanced DHCP Options Set with comprehensive private FQDN support
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
  
  # NetBIOS name servers (for Windows compatibility)
  netbios_name_servers = [
    "169.254.169.123"             # AWS NTP server (used as placeholder)
  ]
  
  # NetBIOS node type (2 = P-node for point-to-point)
  netbios_node_type = 2

  tags = {
    Name        = "private-fqdn-dhcp-options"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Private FQDN Resolution"
    Description = "DHCP options for private FQDN resolution with Route53"
  }
}

# Associate DHCP Options Set with VPC
resource "aws_vpc_dhcp_options_association" "private_fqdn" {
  vpc_id          = data.aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.private_fqdn.id
}

# =============================================================================
# ROUTE53 PRIVATE HOSTED ZONE FOR PRIVATE FQDN
# =============================================================================

# Private Hosted Zone for internal FQDN resolution
resource "aws_route53_zone" "private" {
  name = "internal.${var.domain_name}"

  vpc {
    vpc_id = data.aws_vpc.main.id
  }

  tags = {
    Name        = "private-hosted-zone"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Private FQDN Resolution"
  }
}

# =============================================================================
# PRIVATE FQDN RECORDS
# =============================================================================

# Private FQDN for RDS endpoint
resource "aws_route53_record" "rds_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "mysql.internal.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.mysql.endpoint]

  tags = {
    Name        = "rds-private-fqdn"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "RDS Private FQDN"
  }
}

# Private FQDN for Kubernetes API
resource "aws_route53_record" "k8s_api_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "k8s-api.internal.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.kubernetes_control_plane.private_ip]

  tags = {
    Name        = "k8s-api-private-fqdn"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Kubernetes API Private FQDN"
  }
}

# Private FQDN for VPN server
resource "aws_route53_record" "vpn_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "vpn.internal.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.wireguard_vpn_server.private_ip]

  tags = {
    Name        = "vpn-private-fqdn"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "VPN Server Private FQDN"
  }
}

# Private FQDN for Jump Host
resource "aws_route53_record" "jump_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "jump.internal.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.jump_host.private_ip]

  tags = {
    Name        = "jump-private-fqdn"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Jump Host Private FQDN"
  }
}

# Private FQDN for Load Balancer (ALB)
resource "aws_route53_record" "alb_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "alb.internal.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.rds_app_alb.dns_name
    zone_id                = aws_lb.rds_app_alb.zone_id
    evaluate_target_health = true
  }

  tags = {
    Name        = "alb-private-fqdn"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "ALB Private FQDN"
  }
}

# Private FQDN for Load Balancer (NLB)
resource "aws_route53_record" "nlb_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "nlb.internal.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.rds_app_nlb.dns_name
    zone_id                = aws_lb.rds_app_nlb.zone_id
    evaluate_target_health = true
  }

  tags = {
    Name        = "nlb-private-fqdn"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "NLB Private FQDN"
  }
}

# Private FQDN for Kubernetes Workers (round-robin)
resource "aws_route53_record" "k8s_workers_private" {
  count   = length(aws_instance.kubernetes_worker)
  zone_id = aws_route53_zone.private.zone_id
  name    = "k8s-worker-${count.index + 1}.internal.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.kubernetes_worker[count.index].private_ip]

  tags = {
    Name        = "k8s-worker-${count.index + 1}-private-fqdn"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Kubernetes Worker Private FQDN"
  }
}

# Private FQDN for Kubernetes Workers (load balanced)
resource "aws_route53_record" "k8s_workers_lb_private" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "k8s-workers.internal.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [for instance in aws_instance.kubernetes_worker : instance.private_ip]

  tags = {
    Name        = "k8s-workers-lb-private-fqdn"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Kubernetes Workers Load Balanced Private FQDN"
  }
}

# =============================================================================
# VPC ENDPOINT FOR ROUTE53
# =============================================================================

# VPC Endpoint for Route53 (for private DNS resolution)
resource "aws_vpc_endpoint" "route53" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.route53"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id, aws_subnet.private_2.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "route53-vpc-endpoint"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Route53 Private DNS Resolution"
  }
}

# =============================================================================
# DNS RESOLVER CONFIGURATION
# =============================================================================

# DNS Resolver for private FQDN resolution
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

  tags = {
    Name        = "private-dns-resolver"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Private DNS Resolution"
  }
}

# DNS Resolver Rule for private FQDN forwarding
resource "aws_route53_resolver_rule" "private" {
  domain_name          = "internal.${var.domain_name}"
  name                 = "private-fqdn-rule"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.private.id

  target_ip {
    ip = "169.254.169.253"  # AWS VPC DNS resolver
  }

  tags = {
    Name        = "private-fqdn-rule"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Private FQDN Forwarding"
  }
}

# Associate DNS Resolver Rule with VPC
resource "aws_route53_resolver_rule_association" "private" {
  resolver_rule_id = aws_route53_resolver_rule.private.id
  vpc_id           = data.aws_vpc.main.id
}

# =============================================================================
# OUTPUTS
# =============================================================================

# Output private FQDN information
output "private_fqdn_info" {
  description = "Private FQDN configuration information"
  value = {
    domain_name           = "internal.${var.domain_name}"
    rds_private_fqdn      = "mysql.internal.${var.domain_name}"
    k8s_api_private_fqdn  = "k8s-api.internal.${var.domain_name}"
    vpn_private_fqdn      = "vpn.internal.${var.domain_name}"
    jump_private_fqdn     = "jump.internal.${var.domain_name}"
    alb_private_fqdn      = "alb.internal.${var.domain_name}"
    nlb_private_fqdn      = "nlb.internal.${var.domain_name}"
    dhcp_options_id       = aws_vpc_dhcp_options.private_fqdn.id
    private_zone_id       = aws_route53_zone.private.zone_id
  }
}

# Output DNS resolver information
output "dns_resolver_info" {
  description = "DNS resolver configuration information"
  value = {
    resolver_endpoint_id = aws_route53_resolver_endpoint.private.id
    resolver_rule_id     = aws_route53_resolver_rule.private.id
    vpc_endpoint_id      = aws_vpc_endpoint.route53.id
  }
}
