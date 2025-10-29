# EC2-Only Terraform configuration
# This version works with your existing VPC and EC2 permissions only

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region  = "us-east-1"
  profile = "eu-north-1" # Use your working profile
}

# Data source for availability zones only

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Single SSH Key Pair for all instances
resource "tls_private_key" "ssh_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create key pair for SSH access
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "go-mysql-api-key"
  public_key = tls_private_key.ssh_key_pair.public_key_openssh
}

# Create security group for EC2 instances
resource "aws_security_group" "ec2_security_group" {
  name_prefix = "go-mysql-api-ec2-sg-"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "SSH from VPN and VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN ranges
  }

  # Kubernetes API access from VPN
  ingress {
    description = "Kubernetes API from VPN"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN ranges
  }

  # Go API port accessible from VPN
  ingress {
    description = "Go API port from VPN"
    from_port   = 8088
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN ranges
  }

  # Private package repository access
  ingress {
    description = "Private package repository access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN ranges
  }

  # MySQL port accessible from VPN
  ingress {
    description = "MySQL port from VPN"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN ranges
  }

  egress {
    description = "Outbound TCP to internet"
    from_port   = 1
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound UDP to internet"
    from_port   = 1
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound ICMP to internet"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "go-mysql-api-ec2-sg"
    Environment = "test"
    Service     = "go-mysql-api"
  }
}

# Create new VPC with 172.16.0.0/16 CIDR
# Use existing VPC
data "aws_vpc" "main" {
  id = "vpc-09e6df90ee7a2f9cf" # Existing VPC with 172.16.0.0/16
}

# VPC Endpoint Security Group
resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "vpc-endpoint-"
  vpc_id      = data.aws_vpc.main.id

  # HTTPS traffic from private subnets
  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16"]
  }

  # All outbound traffic allowed
  # Restrictive outbound rules for secure internet access
  egress {
    description = "HTTPS outbound (secure internet access)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS outbound (domain resolution)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "VPC internal TCP communication"
    from_port   = 1
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"]
  }

  egress {
    description = "VPC internal UDP communication"
    from_port   = 1
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"]
  }

  egress {
    description = "VPC internal ICMP communication"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"]
  }

  egress {
    description = "VPC internal IPSec ESP communication"
    from_port   = -1
    to_port     = -1
    protocol    = "50" # IPSec ESP
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"]
  }

  egress {
    description = "VPC internal IPSec AH communication"
    from_port   = -1
    to_port     = -1
    protocol    = "51" # IPSec AH
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"]
  }

  tags = {
    Name        = "vpc-endpoint-sg"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "VPC Endpoint Security Group"
  }
}

# DHCP Options Set for internal private FQDNs
resource "aws_vpc_dhcp_options" "main" {
  domain_name         = "internal.${var.domain_name}"
  domain_name_servers = ["AmazonProvidedDNS"]

  # Additional DHCP options for enhanced DNS resolution
  ntp_servers = [
    "169.254.169.123" # AWS NTP server
  ]

  netbios_name_servers = [
    "169.254.169.123" # AWS NTP server (used as placeholder)
  ]

  netbios_node_type = 2 # P-node (point-to-point)

  tags = {
    Name        = "main-dhcp-options"
    Environment = var.environment
    Service     = "go-mysql-api"
    Purpose     = "Internal Private FQDN Resolution"
  }
}

# Associate DHCP Options Set with VPC
resource "aws_vpc_dhcp_options_association" "main" {
  vpc_id          = data.aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.main.id
}

# Internet Gateway for secure public NAT Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = data.aws_vpc.main.id

  tags = {
    Name        = "main-igw"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Internet Gateway for secure public NAT Gateway"
  }
}

# Elastic IP for secure public NAT Gateway
resource "aws_eip" "nat_gateway" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "nat-gateway-eip"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Static IP for secure public NAT Gateway"
  }
}

# VPC Endpoints for secure AWS connectivity (no internet access needed)
# S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = data.aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name        = "s3-vpc-endpoint"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Secure S3 access without internet"
  }
}

# ECR VPC Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "ecr-dkr-vpc-endpoint"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Secure ECR access without internet"
  }
}

# ECR API VPC Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "ecr-api-vpc-endpoint"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Secure ECR API access without internet"
  }
}

# CloudWatch Logs VPC Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "logs-vpc-endpoint"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Secure CloudWatch Logs access without internet"
  }
}

# Create 1 public subnet (for secure public NAT Gateway only)
resource "aws_subnet" "public" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = "172.16.1.0/28" # Public subnet (16 IPs)
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false # Security: No instances should get public IPs

  tags = {
    Name        = "public"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Public Subnet for secure public NAT Gateway"
  }
}

# Secure public NAT Gateway (with EIP and Internet Gateway)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name        = "main-nat-gateway"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Secure public NAT Gateway for controlled internet access"
  }
}

# Create 1 private subnet (for all instances)
resource "aws_subnet" "private" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = "172.16.2.0/28" # Private subnet (16 IPs)
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name        = "private"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Private Subnet for all instances"
  }
}



# Route53 Private Hosted Zone for private DNS resolution
resource "aws_route53_zone" "private" {
  name = var.domain_name

  vpc {
    vpc_id = data.aws_vpc.main.id
  }

  tags = {
    Name        = "private-zone"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Private DNS Resolution"
  }
}

# Load Balancer for Kubernetes API
resource "aws_lb" "kubernetes_api" {
  name               = "k8s-api-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.private.id]

  enable_deletion_protection = false

  tags = {
    Name        = "k8s-api-lb"
    Environment = "test"
    Service     = "kubernetes"
  }
}

# Target Group for Kubernetes API
resource "aws_lb_target_group" "kubernetes_api" {
  name     = "k8s-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTPS"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "k8s-api-tg"
    Environment = "test"
    Service     = "kubernetes"
  }
}

# Target Group Attachment for Kubernetes Control Plane
resource "aws_lb_target_group_attachment" "kubernetes_api" {
  target_group_arn = aws_lb_target_group.kubernetes_api.arn
  target_id        = aws_instance.kubernetes_control_plane.id
  port             = 6443
}

# Load Balancer Listener for Kubernetes API
resource "aws_lb_listener" "kubernetes_api" {
  load_balancer_arn = aws_lb.kubernetes_api.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kubernetes_api.arn
  }
}

# DNS Records for private services
resource "aws_route53_record" "kubernetes_api" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "k8s-api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.kubernetes_api.dns_name
    zone_id                = aws_lb.kubernetes_api.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "vpn_server" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "vpn.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.wireguard_vpn_server.private_ip]
}

resource "aws_route53_record" "jump_host" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "jump.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.jump_host.private_ip]
}

# MySQL API FQDN
resource "aws_route53_record" "mysql_api" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.kubernetes_control_plane.private_ip]
}

# Note: MySQL Database FQDN is now defined in rds.tf
# This provides proper RDS endpoint resolution with VPC association authorization

# Create public route table (Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "public-rt"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Public Route Table - Internet Gateway"
  }
}

# Create private route table (NAT Gateway + VPC Endpoints)
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.main.id

  # Internet access via secure public NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  # S3 Gateway endpoint is automatically added to this route table

  tags = {
    Name        = "private-rt"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Private Route Table - Secure NAT Gateway + VPC Endpoints"
  }
}

# GO-MYSQL API as JUMP HOST for accessing private instances

# Create go-mysql instance (acts as jump host)
resource "aws_instance" "go_mysql_jump_host" {
  ami                    = "ami-0c02fb55956c7d316" # Debian 12 (Bookworm) - Secure, minimal attack surface
  instance_type          = "t3.micro"              # Small instance for jump host
  key_name               = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.jump_host_secure.id]
  subnet_id              = aws_subnet.private.id # Private subnet
  private_ip             = "172.16.2.10"         # Static private IP for predictable FQDN

  associate_public_ip_address = false # No public IP - access via VPN only

  user_data = base64encode(templatefile("templates/go-mysql-jump-host.yml", {
    environment    = "test"
    service_name   = "go-mysql-api"
    domain_name    = "internal.${var.domain_name}"
    ssh_public_key = tls_private_key.ssh_key_pair.public_key_openssh
    # Security hardening
    enable_firewall = "true"
    restrict_ssh    = "true"
    enable_logging  = "true"
    # Access to private instances
    kubernetes_private_ip = aws_instance.kubernetes_control_plane.private_ip
    vpn_private_ip        = aws_instance.wireguard_vpn_server.private_ip
    vpc_cidr              = "172.16.0.0/16"
  }))

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true # EBS encryption
  }

  metadata_options {
    http_tokens                 = "required" # IMDSv2 required - prevents SSRF attacks
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1 # Prevent SSRF attacks
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name        = "go-mysql-jump-host"
    Environment = "test"
    Service     = "go-mysql-api"
    Role        = "jump-host"
    Purpose     = "Go-MySQL API + Jump Host Access"
    Security    = "high"
  }
}

# Security group for jump host (maximum security - VPN access only)
resource "aws_security_group" "jump_host_secure" {
  name_prefix = "jump-host-secure-"
  vpc_id      = data.aws_vpc.main.id

  # SSH access from VPN clients and VPC internal
  ingress {
    description = "SSH from VPN clients and VPC internal"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN ranges
  }

  # Restricted outbound - only to VPC and VPN
  egress {
    description = "Outbound TCP to VPC and VPN only"
    from_port   = 1
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN only
  }

  egress {
    description = "Outbound UDP to VPC and VPN only"
    from_port   = 1
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN only
  }

  egress {
    description = "Outbound ICMP to VPC and VPN only"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN only
  }

  tags = {
    Name        = "jump-host-secure-sg"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Secure Jump Host Access"
    Security    = "high"
  }
}

# HYBRID SECURE VPN Infrastructure - Maximum Security + Flexibility

# WireGuard keys will be generated by CloudInit during instance boot
# This provides better security as keys are generated on the instance itself

# Create WireGuard VPN server in private subnet (maximum security)
resource "aws_instance" "wireguard_vpn_server" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2023
  instance_type          = "t3.micro"              # Cost-effective
  key_name               = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.wireguard_vpn_secure.id]
  subnet_id              = aws_subnet.private.id # Private subnet for VPN server (Zero Trust)
  private_ip             = "172.16.2.11"         # Static private IP for predictable FQDN

  associate_public_ip_address = false # No public IP - access via jump host only

  user_data = base64encode(templatefile("templates/wireguard-server-secure.yml", {
    environment       = "test"
    service_name      = "go-mysql-api"
    domain_name       = "internal.${var.domain_name}"
    ssh_public_key    = tls_private_key.ssh_key_pair.public_key_openssh
    vpn_subnet        = "10.100.0.0/24"
    vpn_server_ip     = "10.100.0.1"
    vpn_client_ip     = "10.100.0.2"
    kubernetes_subnet = "172.16.100.0/24"
    vpc_cidr          = "172.16.0.0/16"
    # Security hardening
    enable_firewall = "true"
    restrict_ssh    = "true"
    enable_logging  = "true"
  }))

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true # EBS encryption
  }

  metadata_options {
    http_tokens                 = "required" # IMDSv2 required - prevents SSRF attacks
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1 # Prevent SSRF attacks
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name        = "secure-wireguard-vpn-server"
    Environment = "test"
    Service     = "go-mysql-api"
    Role        = "vpn-server"
    Purpose     = "Hybrid Secure VPN - Maximum Security"
    Security    = "high"
  }
}

# ULTRA-SECURE Security Group for WireGuard VPN
resource "aws_security_group" "wireguard_vpn_secure" {
  name_prefix = "wireguard-vpn-ultra-secure-"
  vpc_id      = data.aws_vpc.main.id

  # WireGuard VPN port (UDP 51820) - Zero Trust: No external access
  # Note: VPN server is in private subnet - no external access possible
  # This ingress rule is kept for completeness but won't be used
  ingress {
    description = "WireGuard VPN - Zero Trust (Private Only)"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["172.16.0.0/16"] # Only VPC internal (Zero Trust)
  }

  # IKEv2/IPSec VPN ports (alternative to WireGuard)
  ingress {
    description = "IKEv2/IPSec VPN port - Zero Trust (Private Only)"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["172.16.0.0/16"] # IKE negotiation
  }

  ingress {
    description = "IPSec NAT-T port - Zero Trust (Private Only)"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["172.16.0.0/16"] # IPSec NAT traversal
  }

  # IPSec ESP and AH protocols
  ingress {
    description = "IPSec ESP protocol - Zero Trust (Private Only)"
    from_port   = -1
    to_port     = -1
    protocol    = "50" # IPSec ESP
    cidr_blocks = ["172.16.0.0/16"]
  }

  ingress {
    description = "IPSec AH protocol - Zero Trust (Private Only)"
    from_port   = -1
    to_port     = -1
    protocol    = "51" # IPSec AH
    cidr_blocks = ["172.16.0.0/16"]
  }

  # SSH access ONLY from jump host/VPC (no public SSH)
  ingress {
    description = "SSH from jump host/VPC only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16"] # VPC internal access only
  }

  # Kubernetes API access from VPN clients
  ingress {
    description = "Kubernetes API from VPN clients"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.100.0.0/24"] # Only from VPN subnet
  }

  # Go API access from VPN clients
  ingress {
    description = "Go API from VPN clients"
    from_port   = 8088
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = ["10.100.0.0/24"] # Only from VPN subnet
  }

  # MySQL access from VPN clients only
  ingress {
    description = "MySQL from VPN clients only"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.100.0.0/24"] # Only from VPN subnet
  }

  # Restricted outbound - only necessary traffic
  egress {
    description = "Outbound TCP to VPC and VPN clients only"
    from_port   = 1
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN only
  }

  egress {
    description = "Outbound UDP to VPC and VPN clients only"
    from_port   = 1
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN only
  }

  egress {
    description = "Outbound ICMP to VPC and VPN clients only"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN only
  }

  egress {
    description = "Outbound IPSec ESP to VPC and VPN clients only"
    from_port   = -1
    to_port     = -1
    protocol    = "50"                               # IPSec ESP
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN only
  }

  egress {
    description = "Outbound IPSec AH to VPC and VPN clients only"
    from_port   = -1
    to_port     = -1
    protocol    = "51"                               # IPSec AH
    cidr_blocks = ["172.16.0.0/16", "10.100.0.0/24"] # VPC + VPN only
  }

  tags = {
    Name        = "wireguard-vpn-ultra-secure-sg"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Ultra-Secure WireGuard VPN"
    Security    = "maximum"
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Associate private subnet with private route table (NAT Gateway + VPC Endpoints)
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# =============================================================================
# VPC NETWORK ACLs (Network-Level Security)
# =============================================================================
# VPC ACLs provide network-level security and are stateless
# They complement security groups (which are stateful)

# Public subnet ACL (for NAT Gateway)
resource "aws_network_acl" "public" {
  vpc_id = data.aws_vpc.main.id

  # Allow HTTP/HTTPS outbound (for NAT Gateway)
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow DNS outbound
  egress {
    protocol   = "udp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }

  # Allow NTP outbound
  egress {
    protocol   = "udp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 123
    to_port    = 123
  }

  # Allow VPC internal TCP communication
  egress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "172.16.0.0/16"
    from_port  = 1
    to_port    = 65535
  }

  # Allow VPC internal UDP communication
  egress {
    protocol   = "udp"
    rule_no    = 145
    action     = "allow"
    cidr_block = "172.16.0.0/16"
    from_port  = 1
    to_port    = 65535
  }

  # Allow VPC internal ICMP communication
  egress {
    protocol   = "icmp"
    rule_no    = 147
    action     = "allow"
    cidr_block = "172.16.0.0/16"
    from_port  = -1
    to_port    = -1
  }

  # Allow VPN subnet TCP communication
  egress {
    protocol   = "tcp"
    rule_no    = 150
    action     = "allow"
    cidr_block = "10.100.0.0/24"
    from_port  = 1
    to_port    = 65535
  }

  # Allow VPN subnet UDP communication
  egress {
    protocol   = "udp"
    rule_no    = 155
    action     = "allow"
    cidr_block = "10.100.0.0/24"
    from_port  = 1
    to_port    = 65535
  }

  # Allow VPN subnet ICMP communication
  egress {
    protocol   = "icmp"
    rule_no    = 157
    action     = "allow"
    cidr_block = "10.100.0.0/24"
    from_port  = -1
    to_port    = -1
  }

  # Allow HTTP/HTTPS inbound (for NAT Gateway)
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow VPC internal communication
  ingress {
    protocol   = "-1"
    rule_no    = 120
    action     = "allow"
    cidr_block = "172.16.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  # Allow VPN subnet communication
  ingress {
    protocol   = "-1"
    rule_no    = 130
    action     = "allow"
    cidr_block = "10.100.0.0/24"
    from_port  = 0
    to_port    = 0
  }

  # Deny all other traffic
  egress {
    protocol   = "-1"
    rule_no    = 32767
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 32767
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "public-subnet-acl"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Public Subnet Network ACL"
  }
}

# Private subnet ACL (for all instances) - DUAL AUTHENTICATION
resource "aws_network_acl" "private" {
  vpc_id = data.aws_vpc.main.id

  # Allow HTTP/HTTPS outbound (for package downloads)
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 210
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow DNS outbound
  egress {
    protocol   = "udp"
    rule_no    = 220
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }

  # Allow NTP outbound
  egress {
    protocol   = "udp"
    rule_no    = 230
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 123
    to_port    = 123
  }

  # Allow VPC internal communication
  egress {
    protocol   = "-1"
    rule_no    = 240
    action     = "allow"
    cidr_block = "172.16.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  # Allow VPN subnet communication
  egress {
    protocol   = "-1"
    rule_no    = 250
    action     = "allow"
    cidr_block = "10.100.0.0/24"
    from_port  = 0
    to_port    = 0
  }

  # Allow Kubernetes pod communication
  egress {
    protocol   = "-1"
    rule_no    = 260
    action     = "allow"
    cidr_block = "10.200.0.0/24"
    from_port  = 0
    to_port    = 0
  }

  # Allow Kubernetes service communication
  egress {
    protocol   = "-1"
    rule_no    = 270
    action     = "allow"
    cidr_block = "10.150.0.0/24"
    from_port  = 0
    to_port    = 0
  }

  # SSH access ONLY from VPN subnet (dual authentication)
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.100.0.0/24"
    from_port  = 22
    to_port    = 22
  }

  # WireGuard VPN access from anywhere (for initial connection)
  ingress {
    protocol   = "udp"
    rule_no    = 210
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 51820
    to_port    = 51820
  }

  # VPC internal communication
  ingress {
    protocol   = "-1"
    rule_no    = 220
    action     = "allow"
    cidr_block = "172.16.0.0/16"
    from_port  = 0
    to_port    = 0
  }

  # VPN subnet communication
  ingress {
    protocol   = "-1"
    rule_no    = 230
    action     = "allow"
    cidr_block = "10.100.0.0/24"
    from_port  = 0
    to_port    = 0
  }

  # Kubernetes pod communication
  ingress {
    protocol   = "-1"
    rule_no    = 240
    action     = "allow"
    cidr_block = "10.200.0.0/24"
    from_port  = 0
    to_port    = 0
  }

  # Kubernetes service communication
  ingress {
    protocol   = "-1"
    rule_no    = 250
    action     = "allow"
    cidr_block = "10.150.0.0/24"
    from_port  = 0
    to_port    = 0
  }

  # Deny all other traffic
  egress {
    protocol   = "-1"
    rule_no    = 32767
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 32767
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name        = "private-subnet-acl"
    Environment = "test"
    Service     = "go-mysql-api"
    Purpose     = "Private Subnet Network ACL - Dual Authentication"
  }
}

# Associate ACLs with subnets
resource "aws_network_acl_association" "public" {
  network_acl_id = aws_network_acl.public.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_network_acl_association" "private" {
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private.id
}

# Jump host also uses private route table with NAT Gateway
# (No separate route table needed - uses same private route table)

# VPC Flow Logs - COMMENTED OUT due to IAM permissions
# Will be enabled later when IAM permissions are available

# Jump host uses private_a subnet which is already associated with private route table

# Create EC2 instance for Kubernetes control plane in private subnet
resource "aws_instance" "kubernetes_control_plane" {
  ami                    = "ami-0c02fb55956c7d316" # Bottlerocket OS - Immutable, container-optimized, automatic updates
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  subnet_id              = aws_subnet.private.id # Use private subnet
  private_ip             = "172.16.2.12"         # Static private IP for predictable FQDN

  associate_public_ip_address = false

  user_data = base64encode(templatefile("templates/kubernetes-control-plane-cloudinit.yml", {
    environment                  = "test"
    service_name                 = "go-mysql-api"
    cluster_name                 = "test-go-mysql-api-cluster"
    pod_cidr                     = "10.200.0.0/24"
    service_cidr                 = "10.150.0.0/24"
    rds_endpoint                 = "mysql.${var.domain_name}" # RDS FQDN with VPC association
    rds_port                     = "3306"
    rds_username                 = "admin"
    rds_password                 = var.rds_password
    rds_database                 = "goapp_users"
    kubernetes_api_endpoint      = "https://0.0.0.0:6443" # Will be updated to actual IP after deployment
    vpc_id                       = data.aws_vpc.main.id
    route_table_id               = data.aws_vpc.main.main_route_table_id
    aws_access_key_id            = ""
    aws_secret_access_key        = ""
    route53_zone_id              = ""
    domain_name                  = "internal.${var.domain_name}"
    ssh_public_key               = tls_private_key.ssh_key_pair.public_key_openssh
    enable_multicluster_headless = "false"
    enable_native_sidecars       = "false"
  }))

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens                 = "required" # IMDSv2 required - prevents SSRF attacks
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1 # Prevent SSRF attacks
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name              = "go-mysql-api-kubernetes-control-plane"
    Environment       = "test"
    Service           = "go-mysql-api"
    Role              = "kubernetes-control-plane"
    KubernetesCluster = "test-go-mysql-api-cluster"
  }
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.main.id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value = {
    public_subnet  = aws_subnet.public.id
    private_subnet = aws_subnet.private.id
  }
}

output "kubernetes_control_plane_private_ip" {
  description = "Private IP of Kubernetes control plane"
  value       = aws_instance.kubernetes_control_plane.private_ip
}

output "kubernetes_control_plane_private_dns" {
  description = "Private DNS name of Kubernetes control plane"
  value       = aws_instance.kubernetes_control_plane.private_dns
}

# Go-MySQL Jump Host Outputs
output "go_mysql_jump_host_private_ip" {
  description = "Private IP of go-mysql jump host (access via VPN only)"
  value       = aws_instance.go_mysql_jump_host.private_ip
}

output "go_mysql_jump_host_private_dns" {
  description = "Private DNS name of go-mysql jump host"
  value       = aws_instance.go_mysql_jump_host.private_dns
}

# WireGuard VPN Outputs
# Note: VPN server is private - no public IP

output "wireguard_vpn_server_private_ip" {
  description = "Private IP of WireGuard VPN server"
  value       = aws_instance.wireguard_vpn_server.private_ip
}

output "wireguard_vpn_server_private_dns" {
  description = "Private DNS name of WireGuard VPN server"
  value       = aws_instance.wireguard_vpn_server.private_dns
}

# WireGuard keys are generated by CloudInit and stored locally on the VPN server
# For security, keys are not exposed in Terraform outputs

# Route53 Outputs - COMMENTED OUT
# output "private_zone_id" {
#   description = "Route53 Private Hosted Zone ID"
#   value       = aws_route53_zone.private.zone_id
# }
# 
# output "kubernetes_api_fqdn" {
#   description = "Kubernetes API FQDN (private)"
#   value       = aws_route53_record.kubernetes_api.fqdn
# }
# 
# output "vpn_server_fqdn" {
#   description = "VPN Server FQDN (private)"
#   value       = aws_route53_record.vpn_server.fqdn
# }
# 
# output "jump_host_fqdn" {
#   description = "Jump Host FQDN (private)"
#   value       = aws_route53_record.jump_host.fqdn
# }
# 
# output "mysql_api_fqdn" {
#   description = "MySQL API FQDN (private)"
#   value       = aws_route53_record.mysql_api.fqdn
# }

# RDS Outputs
output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_fqdn" {
  description = "RDS MySQL FQDN (private)"
  value       = aws_route53_record.mysql_database.fqdn
}

output "rds_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.mysql.port
}

output "ssh_private_key" {
  description = "SSH private key for all instances"
  value       = tls_private_key.ssh_key_pair.private_key_pem
  sensitive   = true
}

output "ssh_public_key" {
  description = "SSH public key for all instances"
  value       = tls_private_key.ssh_key_pair.public_key_openssh
}

