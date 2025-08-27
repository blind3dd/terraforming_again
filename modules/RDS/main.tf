module "rds" {
    source = "../../rds"
  
    environment = var.environment
    service_name = var.service_name
    infra_builder = var.infra_builder
    aws_region = var.aws_region
    main_vpc_cidr = var.main_vpc_cidr
    private_subnet_range_a = var.private_subnet_range_a
    private_subnet_range_b = var.private_subnet_range_b
    public_subnet_range_a = var.public_subnet_range
}

resource "aws_db_subnet_group" "private_db_subnet" {
  name        = "mysql-rds-private-subnet-group"
  description = "Private subnets for RDS instance"
  subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "${var.environment}-rds-sg"
  description = "Allow inbound/outbound MySQL traffic"
  vpc_id      = aws_vpc.main.id
  depends_on  = [aws_vpc.main]
}

# Allow inbound MySQL connections
resource "aws_security_group_rule" "allow_mysql_in" {
  description              = "Allow inbound MySQL connections"
  type                     = "ingress"
  from_port                = "3306"
  to_port                  = "3306"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.default.id
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
  password = data.aws_ssm_parameter.db_password.value

  db_subnet_group_name = aws_db_subnet_group.private_db_subnet.name 
  skip_final_snapshot = true

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]
}