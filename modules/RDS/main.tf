# Note: The module "rds" call was removed as it was referencing a non-existent module
# The RDS resources are defined directly in this file

# Note: These resources reference VPC and subnet resources that should be passed as data sources
# or the RDS module should be called from within the VPC module context

# Data sources to reference existing VPC and subnets
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-vpc"]
  }
}

data "aws_subnet" "private_subnet_a" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-public-subnet-a"]
  }
}

data "aws_subnet" "private_subnet_b" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-public-subnet-b"]
  }
}

data "aws_security_group" "default" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-default-sg"]
  }
}

resource "aws_db_subnet_group" "private_db_subnet" {
  name        = "mysql-rds-private-subnet-group"
  description = "Private subnets for RDS instance"
  subnet_ids = [data.aws_subnet.private_subnet_a.id, data.aws_subnet.private_subnet_b.id]
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "${var.environment}-rds-sg"
  description = "Allow inbound/outbound MySQL traffic"
  vpc_id      = data.aws_vpc.main.id
}

# Allow inbound MySQL connections
resource "aws_security_group_rule" "allow_mysql_in" {
  description              = "Allow inbound MySQL connections"
  type                     = "ingress"
  from_port                = "3306"
  to_port                  = "3306"
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.default.id
  security_group_id        = aws_security_group.rds_sg.id
}

# RDS Instance
resource "aws_db_instance" "mysql_8" {
  allocated_storage = 10
  identifier = "${var.environment}-${var.service_name}-rds"
  storage_type = "gp2"
  engine = "mysql"
  
  engine_version = "8.0.32"
  instance_class = "db.t3.micro" 
  multi_az = true

  db_name  = "mock_user"
  username = "mock_pass"
  password = "mock_password_123"  # In production, use SSM parameter store

  db_subnet_group_name = aws_db_subnet_group.private_db_subnet.name 
  skip_final_snapshot = true

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]
}