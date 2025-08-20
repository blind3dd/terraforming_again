

module "vpc" {
  source = "../common/vpc"
  region = var.region
  environment = var.environment
  main_vpc_cidr = var.main_vpc_cidr
  private_subnet_range_a = var.private_subnet_range_a
  private_subnet_range_b = var.private_subnet_range_b
  public_subnet_range_a = var.public_subnet_range
  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  db_port = var.db_port
  db_engine = var.db_engine
  db_engine_version = var.db_engine_version
  db_instance_class = var.db_instance_class
}

module "rds" {
  source = "../common/rds"
  region = var.region
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  private_subnet_range_a = var.private_subnet_range_a
  private_subnet_range_b = var.private_subnet_range_b
  public_subnet_range_a = var.public_subnet_range
  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  db_port = var.db_port
  db_engine = var.db_engine
  db_engine_version = var.db_engine_version
  db_instance_class = var.db_instance_class
}

module "ec2" {
  source = "../common/ec2"
  region = var.region
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  private_subnet_range_a = var.private_subnet_range_a
  private_subnet_range_b = var.private_subnet_range_b
  public_subnet_range_a = var.public_subnet_range
  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  db_port = var.db_port
  db_engine = var.db_engine
  db_engine_version = var.db_engine_version
  db_instance_class = var.db_instance_class
}