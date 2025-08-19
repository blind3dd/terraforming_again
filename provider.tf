

provider local {
  

}

provider "vpc" {
  region = var.region

}

provider "ull" {
  region = var.region

}

provider "tls" {
  

}



terraform {
  required_providers {


    aws = {
      source = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    local = {
      source = "hashicorp/local"
      version = ">= 2.0.0"
    }
    null = {
      source = "hashicorp/null"
    }
    vpc = {
      source = "hashicorp/vpc"
      version = ">= 3.0.0"
    }
    subnets = {
      source = "hashicorp/subnets"
      version = ">= 1.0.0"
    }

  }
}





