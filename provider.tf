terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = ">= 5.0.0"
        }
        local = {
            source = "hashicorp/local"
            version = ">= 2.0.0"
        }
        null = {
            source = "hashicorp/null"
            version = ">= 3.0.0"
        }
        random = {
            source = "hashicorp/random"
            version = ">= 3.0.0"
        }
        tls = {
            source = "hashicorp/tls"
            version = ">= 4.0.0"
        }
        external = {
            source = "hashicorp/external"
            version = ">= 2.0.0"
        }
    }
}

# Configure the AWS Provider
provider "aws" {
    region = var.region
    # Uncomment and set your AWS credentials if needed
    # access_key = "your-access-key"
    # secret_key = "your-secret-key"
}

# Configure other providers as needed
provider "local" {
}

provider "null" {
}

provider "random" {
}

provider "tls" {
}

provider "external" {
}
 
   