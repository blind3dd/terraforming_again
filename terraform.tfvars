# AWS Configuration
region = "us-east-1"
environment = "test"
service_name = "go-mysql-api"

# VPC Configuration
main_vpc_cidr = "172.31.0.0/16"
private_subnet_range_a = "172.31.16.0/20"
private_subnet_range_b = "172.31.32.0/20"
public_subnet_range = "172.31.48.0/20"

# Existing VPC ID (use your existing VPC)
existing_vpc_id = "vpc-0d3809169f49c513a"
existing_subnet_ids = ["subnet-000bc8b855976960c", "subnet-0050057a15b4d9842", "subnet-04cb4552dbf592d86", "subnet-0339e68281f11b772", "subnet-0d0d7a12505354fec", "subnet-0fdc39554271a86fa"]

# Instance Configuration
instance_type = "t3.medium"
instance_ami = "ami-0c02fb55956c7d316"  # Amazon Linux 2023 in us-east-1
instance_os = "Amazon Linux 2023"
associate_public_ip_address = true

# Database Configuration
db_name = "mock_user"
db_username = "db_user"
db_password = "SecurePassword123!"
db_instance_class = "db.t3.micro"
db_engine_version = "8.0.35"

# Key Pair Configuration
aws_key_pair_name = "go-mysql-api-key"
key_algorithm = "RSA"
key_bits_size = 4096

# Infrastructure Configuration
infra_builder = "terraform"
db_password_param = "/test/go-mysql-api/db/password"

# AWS Credentials (you'll need to set these)
aws_access_key_id = ""
aws_secret_access_key = ""
route53_zone_id = ""
domain_name = "coderedalarmtech.com"
