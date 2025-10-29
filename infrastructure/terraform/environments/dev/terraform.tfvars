# AWS Configuration
region       = "us-east-1"
environment  = "dev"
service_name = "go-mysql-api"
project_name = "terraforming-again"

# VPC Configuration (Private IP ranges like Azure)
vpc_cidr             = "172.16.0.0/16"
public_subnet_cidrs  = ["172.16.10.0/24", "172.16.11.0/24", "172.16.12.0/24"]
private_subnet_cidrs = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]

# DHCP Options for Private FQDNs (like Azure)
create_dhcp_options      = true
domain_name              = "internal.coderedalarmtech.com"
dhcp_domain_name_servers = ["AmazonProvidedDNS"]
dhcp_ntp_servers         = ["169.254.169.123"]

# Existing VPC ID (use your existing VPC if needed)
existing_vpc_id     = "vpc-0d3809169f49c513a"
existing_subnet_ids = ["subnet-000bc8b855976960c", "subnet-0050057a15b4d9842", "subnet-04cb4552dbf592d86", "subnet-0339e68281f11b772", "subnet-0d0d7a12505354fec", "subnet-0fdc39554271a86fa"]

# Instance Configuration (Optimized for Dev - save ~$22/month)
instance_type               = "t3.micro"  # Changed from t3.medium - saves ~$22/month
instance_ami                = "ami-0c02fb55956c7d316" # Amazon Linux 2023 in us-east-1
instance_os                 = "Amazon Linux 2023"
associate_public_ip_address = true

# Database Configuration
db_name           = "mock_user"
db_username       = "db_user"
db_password       = "SecurePassword123!"
db_instance_class = "db.t3.micro"
db_engine_version = "8.0.35"

# Key Pair Configuration
aws_key_pair_name = "go-mysql-api-key"
key_algorithm     = "RSA"
key_bits_size     = 4096

# Infrastructure Configuration
infra_builder     = "terraform"
db_password_param = "/test/go-mysql-api/db/password"

# Tailscale Configuration
tailscale_auth_key = "" # Set this in your environment or SSM
enable_tailscale   = true

# SSH Configuration
ssh_public_key = "" # Set this in your environment or SSM

# Enable NAT Gateway for private subnets (Disabled for Dev - save ~$32/month)
# Use Tailscale exit nodes instead for outbound connectivity
enable_nat_gateway = false  # Changed from true - saves ~$32/month
