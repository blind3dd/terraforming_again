resource "aws_instance" "go_mysql_api" {
	ami                         = var.instance_ami
	instance_type               = var.instance_type
	subnet_id                   = aws_subnet.public_subnet.id
	associate_public_ip_address = var.associate_public_ip_address
	key_name                    = aws_key_pair.ec2_key_pair.key_name
	iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  
	vpc_security_group_ids = [
	  aws_security_group.default.id
	]
	root_block_device {
	  delete_on_termination = true
	  volume_size = 10
	  volume_type = "gp3"
	}

	tags = {
	  Name = "${var.environment}-${var.service_name}-instance"
	  Instance_OS   = var.instance_os
	  Environment = var.environment
	  Service = var.service_name
	  CreatedBy = var.infra_builder
	}
  
	depends_on = [aws_security_group.default, aws_key_pair.ec2_key_pair]
  
	user_data = base64encode(templatefile("user_data.sh", {
	  DB_USER = aws_db_instance.mysql_8.username
	  DB_PASSWORD_PARAM = data.aws_ssm_parameter.db_password.name
	  DB_HOST = aws_db_instance.mysql_8.address
	  DB_PORT = aws_security_group_rule.allow_mysql_in.from_port
	  DB_NAME = aws_db_instance.mysql_8.db_name
	  }))
  }
  
  resource "tls_private_key" "private_rsa_pair" {
	  algorithm = var.key_algorithm
	  rsa_bits  = var.key_bits_size
  }

  resource "aws_key_pair" "ec2_key_pair" {
	  key_name   = var.aws_key_pair_name
	  public_key = tls_private_key.private_rsa_pair.public_key_openssh
  }

  resource "local_sensitive_file" "tf_key" {
	  content              = tls_private_key.private_rsa_pair.private_key_pem
	  file_permission      = "0600"
	  directory_permission = "0700"
	  filename             = "${var.aws_key_pair_name}.pem"
  }
  
  data "aws_ssm_parameter" "db_password" {
    name = var.db_password_param
  }
  
  resource "aws_iam_instance_profile" "instance_profile" {
	  name = "${var.environment}-${var.service_name}-instance-profile"
	  role = aws_iam_role.instance_role.name
  }
  
  resource "aws_iam_role" "instance_role" {
	  name = "${var.environment}-${var.service_name}-instance-role"
    assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
        "Action": "sts:AssumeRole"
      }
    ]
  }
EOF
} 

resource "aws_iam_role_policy_attachment" "instance_policy_attachment" {
	role       = aws_iam_role.instance_role.name
	policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_db_subnet_group" "private_db_subnet" {
  name        = "${var.environment}-${var.service_name}-rds-private-subnet-group"
  description = "Private subnets for RDS instance"
  subnet_ids = [
    for subnet in aws_subnet.private_subnets : subnet.id
  ]
  
  tags = {
    Name = "${var.environment}-${var.service_name}-rds-private-subnet-group"
    Environment = var.environment
    Service = var.service_name
    CreatedBy = var.infra_builder
  }
}

resource "aws_subnet" "cidr" {
  count = length(data.aws_availability_zones.available.names)
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.environment}-${var.service_name}-rds-private-subnet-group"
    Environment = var.environment
    Service = var.service_name
    CreatedBy = var.infra_builder
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.environment}-rds-sg"
  description = "Allow inbound/outbound MySQL traffic"
  vpc_id      = aws_vpc.main.id
  depends_on  = [aws_vpc.main ]
}

resource "aws_security_group_rule" "allow_mysql_in" {
  description              = "Allow inbound MySQL connections"
  type                     = "ingress"
  from_port                = "3306"
  to_port                  = "3306"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.main_vpc_sg.id
  security_group_id        = aws_security_group.rds_sg.id
}

resource "aws_db_instance" "aws_rds_mysql_8" {
  allocated_storage = 10
  identifier = "${var.environment}-${var.service_name}-rds"
  storage_type = "gp2"
  engine = "mysql"
  
  engine_version = var.rds_engine_version
  instance_class = var.instance_type
  multi_az = true

  db_name  = var.db_name
  username = var.db_username
  password = data.aws_ssm_parameter.db_password.value

  db_subnet_group_name = aws_db_subnet_group.private_db_subnet.name 
  skip_final_snapshot = true

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]
}

resource "aws_vpc" "main" {
  cidr_block       = var.main_vpc_cidr
  instance_tenancy = "default"
  
  tags = {  
    Name = "${var.environment}-${var.service_name}-vpc"
	  Instance_OS   = var.instance_os
	  Environment = var.environment
	  Service = var.service_name
	  CreatedBy = var.infra_builder
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-${var.service_name}-igw"
    Environment = var.environment
    Service = var.service_name
    CreatedBy = var.infra_builder
  }
}

# Create 3 subnets: two private and one public
resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_range_a
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.environment}-private-subnet-a"
    Environment = var.environment
    Service = var.service_name
    CreatedBy = var.infra_builder
  }
}

# resource "aws_subnet" "private_subnets" {
#   count = length(data.aws_availability_zones.available.names)
#   vpc_id                  = aws_vpc.main.id 
#   cidr_block              = cidrsubnet(var.main_vpc_cidr, 4, count.index)
#   map_public_ip_on_launch = false
#   availability_zone       = data.aws_availability_zones.available.names[count.index]
  
#   tags = {
#     "Name" = "${var.environment}-private-subnet-b"
#     Environment = var.environment
#     Service = var.service_name
#     CreatedBy = var.infra_builder
#   }
# }

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  count = length(var.public_subnet_range)
  cidr_block = cidrsubnet(var.main_vpc_cidr, len(data.aws_availability_zones.available) % count.index, count.index)
  availability_zone = data.aws_availability_zones.available[count.index]

  tags = {
    "Name" = "${var.environment}-public-subnet-a"
    Environment = var.environment
    Service = var.service_name
    CreatedBy = var.infra_builder
  }
}

# resource "vpc_peering_connection_id" "peering_connection" {
#   vpc_id = aws_vpc.main.id
#   peer_vpc_id = aws_vpc.peer.id
#   peer_owner_id = aws_vpc.peer.owner_id
#   peer_region = var.region
#   tags = {
#     "Name" = "${var.environment}-peering-connection"
#   }
  
//}

resource "aws_nat_gateway" "main" {
  for_each      = aws_subnet.public
  subnet_id     = each.value.id
  allocation_id = aws_eip.main[each.key].id
}

resource "aws_route_table" "nat" {
  for_each = aws_subnet.public_subnet
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main[each.key].id
  }

  tags = {
    "Name" = "${var.environment}-${var.service_name}-private-route-table"
    Environment = var.environment
    Service = var.service_name
    CreatedBy = var.infra_builder
  }
}
locals {
  private_subnets = data.cidr.subnets
}
data "cidr" "private_subnets" {
  name = "private_subnets"
  base_cidr_block = var.main_vpc_cidr
  new_bits = 4
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  # to add proper iterator for private subnets
  for_each = aws_subnet.private_subnet_a
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main[each.key].id
  }
  tags = {
    "Name" = "${var.environment}-private-route-table"
    Environment = var.environment
    Service = var.service_name
    CreatedBy = var.infra_builder
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    "Name" = "${var.environment}-public-route-table"
  }
}

resource "aws_route_table_association" "private_rt_association_a" {
  subnet_id      = aws_subnet.private_subnet_a
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_rt_association_b" {
  subnet_id      = aws_subnet.private_subnet[0].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "main_vpc_sg" {
  name        = "${var.environment}-main-vpc-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = aws_vpc.main.id
  depends_on  = [aws_vpc.main]
}

resource "aws_security_group_rule" "inbound_traffic_ssh" {
  description       = "Allow SSH"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main_vpc_sg.id
}

resource "aws_security_group_rule" "inbound_traffic_http" {
  description       = "Allow inbound HTTPS traffic"
  type              = "ingress"
  from_port         = "3306"
  to_port           = "3306"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main_vpc_sg.id
}

resource "aws_security_group_rule" "outbound_traffic" {
  description       = "Allow outbound traffic"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main_vpc_sg.id
}

resource "aws_security_group" "instance_sg" {
  name = "${var.environment}-${var.service_name}-instance-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-${var.service_name}-instance-sg"
    Environment = var.environment
    Service = var.service_name
    CreatedBy = "Pawel Bek"
  }
}

resource "aws_launch_configuration" "instance_lc" {
  image_id      = var.instance_ami
  instance_type = var.instance_type

  security_groups = ["${aws_security_group.instance_sg.id}"]
  # user_data = <<-EOF
  # EOF

  lifecycle {
    create_before_destroy = true
  }
}


# module "vpc" {
#   source = "../../modules/vpc"
#   environment = var.environment
#   aws_region = var.region
#   main_vpc_cidr = var.main_vpc_cidr
#   private_subnet_range_a = var.private_subnet_range_a
#   private_subnet_range_b = var.private_subnet_range_b
#   public_subnet_range_a = var.public_subnet_range
# }

# module "rds" {
#     source = "../../modules/rds"
#     environment = var.environment
#     service_name = var.service_name
#     infra_builder = var.infra_builder
#     aws_region = var.aws_region
#     main_vpc_cidr = var.main_vpc_cidr
#     private_subnet_range_a = var.private_subnet_range_a
#     private_subnet_range_b = var.private_subnet_range_b
#     public_subnet_range_a = var.public_subnet_range
#f }

# module "ec2" {
#   source = "../../modules/ec2"
#   environment = var.environment
#   aws_region = var.region
#   main_vpc_cidr = var.main_vpc_cidr
#   private_subnet_range_a = var.private_subnet_range_a
#   private_subnet_range_b = var.private_subnet_range_b
#   public_subnet_range_a = var.public_subnet_range
# }


data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name = "region"
    values = ["us-east-1"]
  }
  filter {
    name = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  aws_region_zones = tolist(
    [
  {
    region = "us-west-2" // oregon
    zones  = ["us-west-2a", "us-west-2b"]
  },  
  {
    region = "us-east-1" // virginia
    zones  = ["us-east-1a", "us-east-1b"]
  },
    ]
  )
}

module "regional" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.main_vpc_cidr
  networks = [
    for regional in local.aws_region_zones : {
      name     = regional.region
      new_bits = 8
    }
  ]
}

module "zonal" {
  source   = "hashicorp/subnets/cidr"
  for_each = {
    for net in module.regional.networks : net.name => net
  }

  base_cidr_block = each.value.cidr_block
  networks = [
    for zone in local.aws_region_zones[each.key].zones : {
      name     = regional.region
      new_bits = 5
    }
  ]
}

output "zone_regions" {
  value = tomap({
    for net in module.regional.networks : net.name => {
      cidr = net.cidr_block
      zones = tomap({
        for subnet in module.zonal[net.name].networks : subnet.name => {
          cidr = subnet.cidr_block
        }
      })
    }
  })
}