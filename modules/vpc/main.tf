# Create the VPC
resource "aws_vpc" "main" {
  cidr_block       = var.main_vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# Create Internet Gateway and attach it to VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${var.environment}-igw"
    Environment = var.environment
  }
}

# Internet Gateway and 3 subnets: two private and one public so Instance
# with microservice can be deployed in private subnet and access the internet after
# reachig the database in private subnet to get data securely.
resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_range_a
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"

  tags = {
    "Name" = "${var.environment}-public-subnet-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_range_b
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags = {
    "Name" = "${var.environment}-public-subnet-b"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_range
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    "Name" = "${var.environment}-public-subnet-a"
  }
}

# Create Route table for Private Subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "${var.environment}-private-route-table"
  }
}

# Create Route table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    # Traffic from Public Subnet reaches Internet via Internet Gateway
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "${var.environment}-public-route-table"
    Environment = var.environment
    Service = var.service_name
    CreatedBy = var.infra_builder
  }
}

# Route table Association with Private Subnet A
resource "aws_route_table_association" "private_rt_association_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}

# Route table Association with Private Subnet B
resource "aws_route_table_association" "private_rt_association_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}

# Route table Association with Public Subnet A
resource "aws_route_table_association" "public_rt_association_a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = aws_vpc.main.id
  depends_on  = [aws_vpc.main]
}

# Allow inbound SSH for EC2 instances
resource "aws_security_group_rule" "allow_ssh_in" {
  description       = "Allow SSH"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}

resource "aws_security_group_rule" "allow_http_in_api" {
  description       = "Allow inbound HTTPS traffic"
  type              = "ingress"
  from_port         = "8090"
  to_port           = "8090"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_out" {
  description       = "Allow outbound traffic"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
}

resource "aws_security_group" "instance" {
  name = "${var.environment}-${var.service_name}-ec2"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-${var.service_name}-ec2"
    Environment = var.environment
    Service = var.service_name
    CreatedBy = var.infra_builder
  }
}

resource "aws_launch_configuration" "example" {
  image_id      = var.ec2_instance_ami.id
  instance_type = var.ec2_instance_type.id

  security_groups = ["${aws_security_group.instance.id}"]
  # user_data = <<-EOF
  # EOF

  lifecycle {
    create_before_destroy = true
  }
}

module "vpc" {
  source = "./modules/vpc"
  environment = var.environment
  aws_region = var.region
  main_vpc_cidr = var.main_vpc_cidr
  private_subnet_range_a = var.private_subnet_range_a
  private_subnet_range_b = var.private_subnet_range_b
  public_subnet_range_a = var.public_subnet_range
  service_name = var.service_name     
}

module "cidr" {
  source = "./cidr"  

}