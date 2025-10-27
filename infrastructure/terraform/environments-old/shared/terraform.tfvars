# Shared Environment Configuration
# Common values for all environments

project_name = "database-ci"
owner        = "infrastructure-team"
cost_center  = "engineering"
environment  = "shared"
aws_region   = "us-east-1"

# VPC Configuration
create_vpc = true
vpc_cidr   = "10.0.0.0/16"

# Availability Zones
availability_zones = [
  "us-east-1a",
  "us-east-1b", 
  "us-east-1c"
]

# Public Subnets
public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

# Private Subnets
private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24",
  "10.0.13.0/24"
]

# Domain Configuration
domain_name    = "coderedalarmtech.com"
internal_domain = "internal.coderedalarmtech.com"
