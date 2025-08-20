provider "local" {
}
    

  provider "subnets" {
    required_providers {
      cidr = {
        source = "hashicorp/subnets"
        version = ">= 1.0.0"
      }
    }
}


terraform {
  required_providers {
    subnets = {
      source = "hashicorp/subnets"
      version = ">= 2.0.0"
    }
    # cidr = {
    #   source = "hashicorp/subnets/cidr"
    #   version = ">= 1.0.0"
    # }
    # cidr = {
    #   source = "hashicorp/cidr"
    #   version = ">= 1.0.0"
    # }
    tls = {
      source = "hashicorp/tls"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

#   source = "local" {}
#   source = "null" {}
#   source = "cidr" {}
#   source = "tls" {}
#   source = "subnets" {}
 

 
    
 

