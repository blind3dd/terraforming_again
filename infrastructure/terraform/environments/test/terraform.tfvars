# Test Environment Configuration
# This file contains the actual values for the test environment

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

environment = "test"
service_name = "go-mysql-api"
project_name = "terraforming-again"
aws_region = "us-east-1"

# =============================================================================
# VPC CONFIGURATION (Private IP ranges like Azure)
# =============================================================================

vpc_cidr = "172.17.0.0/16"
public_subnet_cidrs = ["172.17.10.0/24", "172.17.11.0/24", "172.17.12.0/24"]
private_subnet_cidrs = ["172.17.1.0/24", "172.17.2.0/24", "172.17.3.0/24"]

# DHCP Options for Private FQDNs (like Azure)
create_dhcp_options = true
domain_name = "internal.coderedalarmtech.com"
dhcp_domain_name_servers = ["AmazonProvidedDNS"]
dhcp_ntp_servers = ["169.254.169.123"]

# Security Groups (VPC internal only)
ssh_cidr_blocks = ["172.17.0.0/16"]
http_cidr_blocks = ["172.17.0.0/16"]
https_cidr_blocks = ["172.17.0.0/16"]

# =============================================================================
# INSTANCE CONFIGURATION
# =============================================================================

instance_type = "t3.small"
instance_ami = "ami-0c02fb55956c7d316"  # Amazon Linux 2023
associate_public_ip_address = false  # Private subnets only

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

db_name = "test_user"
db_username = "test_user"
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

# Note: domain_name is already set above for DHCP options
# If you need a different domain for Route53, consider adding a separate variable
route53_zone_id = ""  # Set this in your environment or SSM
