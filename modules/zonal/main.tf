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
  aws_region_zones = tolist([
  {
    region = "us-west-2" // oregon
    zones  = ["us-west-2a", "us-west-2b", "us-west-2c"]
  },  
  {
    region = "us-east-1" // virginia
    zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  },],)
}
locals {
  regional = {
    name = "regional"
    base_cidr_block = var.main_vpc_cidr
    networks = [
      for r in var.aws_region_zones[length(local.aws_region_zones) - 1].region : {
        name     = element(r.region, count.index % length(r.region))
        new_bits = 8
      }
    ]
  }
  zonal = {
    name = "zonal"
    base_cidr_block = var.main_vpc_cidr
    networks = [
      for zone in var.aws_region_zones[length(local.aws_region_zones) - 1] : {
        name     = element(zone.zones[*].name, count.index % length(zone.zones[*].name).name)
        new_bits = 8
      }
    ]
  }
}
module "regional" {
  source   = "./modules/vpc/cidr"
  name = "regional"
  base_cidr_block = var.main_vpc_cidr
  networks = [
    for regional in var.aws_region_zones[var.aws_region_zones_count - 1] : {
      name     = regional.region
      new_bits = 8
    }
  ]
}

module "zonal" {
  required_providers = {
    cidr = {
      source = "./modules/vpc/cidr"
      version = ">= 1.0.0"
    }
  }
  source   = "./modules/vpc" 
  name = "zonal"
  for_each = {
    for net in module.regional.networks : net.name => net
  }

  base_cidr_block = each.value.cidr_block
  networks = [
    for zone in var.aws_region_zones[0].zones : {
      name     = zone
      new_bits = 8
    }
  ]
}

output "zone_regions" {
  value = tomap({
    for net in module.regional.networks : net.name => {
      cidr = net.cidr_block
      zones = tomap({
        for subnet in module.zonal[net.name].networks : subnet.name => {
          cidr = subnet
        }
      })
    }
  })
}