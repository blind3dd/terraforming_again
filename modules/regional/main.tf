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

# Calculate regional subnets using cidrsubnet function
locals {
  regional_networks = [
    for i, region in local.aws_region_zones : {
      name = region.region
      cidr_block = cidrsubnet(var.main_vpc_cidr, 8, i)
    }
  ]
}

# Calculate zonal subnets
locals {
  zonal_networks = flatten([
    for regional in local.regional_networks : [
      for i, zone in local.aws_region_zones[index(local.aws_region_zones[*].region, regional.name)].zones : {
        regional_name = regional.name
        zone_name = zone
        cidr_block = cidrsubnet(regional.cidr_block, 8, i)
      }
    ]
  ])
}

output "regional_networks" {
  value = local.regional_networks
}

output "zonal_networks" {
  value = local.zonal_networks
}

output "zone_regions" {
  value = tomap({
    for net in local.regional_networks : net.name => {
      cidr = net.cidr_block
      zones = tomap({
        for subnet in local.zonal_networks : subnet.zone_name => {
          cidr = subnet.cidr_block
        } if subnet.regional_name == net.name
      })
    }
  })
}