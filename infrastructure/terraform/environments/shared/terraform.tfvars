# Shared Environment Configuration
# This file contains shared resources across all environments

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

environment = "shared"
service_name = "shared-infrastructure"
project_name = "terraforming-again"
aws_region = "us-east-1"

# =============================================================================
# VPC CONFIGURATION (Shared infrastructure)
# =============================================================================

vpc_cidr = "172.19.0.0/16"
public_subnet_cidrs = ["172.19.10.0/24", "172.19.11.0/24", "172.19.12.0/24"]
private_subnet_cidrs = ["172.19.1.0/24", "172.19.2.0/24", "172.19.3.0/24"]

# DHCP Options for Private FQDNs (like Azure)
create_dhcp_options = true
domain_name = "internal.coderedalarmtech.com"
dhcp_domain_name_servers = ["AmazonProvidedDNS"]
dhcp_ntp_servers = ["169.254.169.123"]

# Security Groups (Cross-environment access)
ssh_cidr_blocks = ["172.16.0.0/12"]  # All environment VPCs
http_cidr_blocks = ["172.16.0.0/12"]
https_cidr_blocks = ["172.16.0.0/12"]

# =============================================================================
# INSTANCE CONFIGURATION
# =============================================================================

instance_type = "t3.medium"
instance_ami = "ami-0c02fb55956c7d316"  # Amazon Linux 2023
associate_public_ip_address = false  # Private subnets only

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

db_name = "shared_user"
db_username = "shared_user"
db_instance_class = "db.t3.micro"
db_engine_version = "8.0.35"

# =============================================================================
# TAILSCALE CONFIGURATION
# =============================================================================

tailscale_auth_key = ""  # Set this in your environment or SSM
enable_tailscale = true

# =============================================================================
# SSH CONFIGURATION
# =============================================================================

ssh_public_key = ""  # Set this in your environment or SSM

# =============================================================================
# NETWORKING CONFIGURATION
# =============================================================================

enable_nat_gateway = true

# =============================================================================
# DOMAIN AND DNS CONFIGURATION
# =============================================================================

route53_zone_id = ""  # Set this in your environment or SSM



