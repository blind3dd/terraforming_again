

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
  db_password_param = var.db_password_param 
  db_host_param = var.db_host_param
  db_port_param = var.db_port_param
  db_user_param = var.db_user_param
  db_name_param = var.db_name_param
  common_tags = var.common_tags
  db_password_param_pass = var.db_password_param_pass
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
  db_password_param = var.db_password_param 
  db_host_param = var.db_host_param
  db_port_param = var.db_port_param
  db_user_param = var.db_user_param
  db_name_param = var.db_name_param
  common_tags = var.common_tags
  db_password_param_pass = var.db_password_param_pass
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
  db_password_param = var.db_password_param 
  db_host_param = var.db_host_param
  db_port_param = var.db_port_param
  db_user_param = var.db_user_param
  db_name_param = var.db_name_param
  common_tags = var.common_tags
  db_password_param_pass = var.db_password_param_pass
}

module "ssm" {
  source = "../common/ssm"
  region = var.region
  environment = var.environment
  db_password_param = var.db_password_param 
  db_host_param = var.db_host_param
  db_port_param = var.db_port_param
  db_user_param = var.db_user_param
  db_name_param = var.db_name_param
  common_tags = var.common_tags
  db_password_param_pass = var.db_password_param_pass
  db_password = var.db_password
  db_username = var.db_username
  db_port = var.db_port
  db_engine = var.db_engine
  db_engine_version = var.db_engine_version
  db_instance_class = var.db_instance_class
  db_name = var.db_name
}

module "zonal" {
  source = "../common/zonal"
  region = var.region
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  private_subnet_range_a = var.private_subnet_range_a
  private_subnet_range_b = var.private_subnet_range_b
  public_subnet_range_a = var.public_subnet_range 
  common_tags = var.common_tags
  db_password_param = var.db_password_param 
  db_host_param = var.db_host_param
  db_port_param = var.db_port_param
  db_user_param = var.db_user_param
  db_name_param = var.db_name_param
  db_password_param_pass = var.db_password_param_pass
  db_password = var.db_password
  db_username = var.db_username
  db_port = var.db_port
  db_engine = var.db_engine
  db_engine_version = var.db_engine_version
  db_instance_class = var.db_instance_class
  db_name = var.db_name
}

module "regional" {
  source = "../common/regional"
  region = var.region
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  private_subnet_range_a = var.private_subnet_range_a
  private_subnet_range_b = var.private_subnet_range_b
  public_subnet_range_a = var.public_subnet_range
  common_tags = var.common_tags
  db_password_param = var.db_password_param 
  db_host_param = var.db_host_param
  db_port_param = var.db_port_param
  db_user_param = var.db_user_param
  db_name_param = var.db_name_param
  db_password_param_pass = var.db_password_param_pass
  db_password = var.db_password
  db_username = var.db_username
}
