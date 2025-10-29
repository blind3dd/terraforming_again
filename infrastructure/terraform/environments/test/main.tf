# Test Environment Main Configuration
# This file orchestrates all modules to create the complete infrastructure for test environment

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Local Backend Configuration with Workspace Support
  # Terraform automatically stores workspace state files in:
  # .terraform.tfstate.d/<workspace>/terraform.tfstate
  backend "local" {
    path = "terraform.tfstate"
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Service     = var.service_name
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "terraforming_again"
  }
  
  name_prefix = "${var.project_name}-${var.environment}"
}

# =============================================================================
# NETWORKING MODULE
# =============================================================================

module "networking" {
  source = "../../modules/networking"

  vpc_cidr                  = var.vpc_cidr
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_subnet_cidrs       = var.private_subnet_cidrs
  enable_nat_gateway         = var.enable_nat_gateway
  create_dhcp_options        = var.create_dhcp_options
  domain_name               = var.domain_name
  dhcp_domain_name_servers   = var.dhcp_domain_name_servers
  dhcp_ntp_servers          = var.dhcp_ntp_servers
  ssh_cidr_blocks           = var.ssh_cidr_blocks
  http_cidr_blocks          = var.http_cidr_blocks
  https_cidr_blocks         = var.https_cidr_blocks
  name_prefix               = local.name_prefix
  common_tags               = local.common_tags
}

# =============================================================================
# COMPUTE MODULE
# =============================================================================

module "compute" {
  source = "../../modules/compute"

  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  private_subnet_ids        = module.networking.private_subnet_ids
  private_subnet_cidrs      = var.private_subnet_cidrs
  web_security_group_id     = module.networking.web_security_group_id
  instance_type             = var.instance_type
  instance_ami              = var.instance_ami
  associate_public_ip_address = var.associate_public_ip_address
  ssh_public_key            = var.ssh_public_key
  name_prefix               = local.name_prefix
  common_tags               = local.common_tags
}

# =============================================================================
# DATABASE MODULE
# =============================================================================

module "database" {
  source = "../../modules/database"

  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  database_security_group_id = module.networking.database_security_group_id
  db_name                   = var.db_name
  db_username               = var.db_username
  db_instance_class         = var.db_instance_class
  db_engine_version         = var.db_engine_version
  name_prefix               = local.name_prefix
  common_tags               = local.common_tags
}

# =============================================================================
# TAILSCALE MODULE
# =============================================================================

module "tailscale" {
  count  = var.enable_tailscale ? 1 : 0
  source = "../../modules/tailscale"

  environment                = var.environment
  service_name               = var.service_name
  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_ids
  tailscale_auth_key         = var.tailscale_auth_key
  vpc_cidr                   = var.vpc_cidr
  public_subnet_cidrs        = var.public_subnet_cidrs
  private_subnet_cidrs       = var.private_subnet_cidrs
  domain_name                = var.domain_name
  route53_zone_id            = var.route53_zone_id
  name_prefix                = local.name_prefix
  common_tags                = local.common_tags
}
