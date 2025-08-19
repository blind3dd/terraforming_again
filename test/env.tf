

module "vpc" {
  source = "../common/vpc"
  region = var.region
  environment = var.environment
  main_vpc_cidr = var.main_vpc_cidr
  private_subnet_range_a = var.private_subnet_range_a
  private_subnet_range_b = var.private_subnet_range_b
  public_subnet_range_a = var.public_subnet_range
}

module "rds" {
  source = "../common/rds"
  region = var.region
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  private_subnet_range_a = var.private_subnet_range_a
  private_subnet_range_b = var.private_subnet_range_b
  public_subnet_range_a = var.public_subnet_range
}

module "ec2" {
  source = "../common/ec2"
  region = var.region
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  private_subnet_range_a = var.private_subnet_range_a
  private_subnet_range_b = var.private_subnet_range_b
  public_subnet_range_a = var.public_subnet_range
}