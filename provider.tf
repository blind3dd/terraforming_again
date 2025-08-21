
terraform {
    required_providers {

           regional = { 
            source = "regional/subnets"
            
                       # configuration_aliases = ["hashicorp/regional/subnets/cidr"]

        }
         zonal = {  
            source = "zonal/subnets"
            
            #configuration_aliases = ["hashicorp/zonal/subnets/cidr"]
    
 

        }
        local = {
            source = "local"
            version = ">= 1.0.0"
        }
 
        # cidr = {
        #     source = "cidr"
        #     version = ">= 1.0.0"
        # }
        null = {
            source = "null"
            version = ">= 1.0.0"
        }
        random = {
            source = "random"
            version = ">= 1.0.0"
        }
        tls = {
            source = "tls"
            version = ">= 1.0.0"
        }
        aws = {
            source = "aws"
            version = ">= 1.0.0"
        }
    }


 
        }
# provider "local" {
# }


# provider "cidrsubnets" {
# }

# provider "cidr" {

# }

# provider "subnets" {
# }

# provider "tls" {
# }


# provider "aws" {
      
      
#     }
# provider "random" {
      
#     }
  

#   source = "local" {}
#   source = "null" {}
#   source = "cidr" {}
#   source = "tls" {}
#   source = "subnets" {}
 
   