# Terraform Providers Configuration
# This file defines all required providers and their versions

terraform {
  required_version = ">= 1.0"

  required_providers {
    # AWS Provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Azure Provider
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }

    # Google Cloud Provider
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }

    # IBM Cloud Provider
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.0"
    }

    # Utility Providers
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

    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }

  # S3 Backend Configuration
  backend "s3" {
    bucket         = "terraform-state-bucket" # Replace with your S3 bucket name
    key            = "terraform.tfstate"
    region         = "us-east-1"            # Replace with your preferred region
    dynamodb_table = "terraform-state-lock" # Replace with your DynamoDB table name
    encrypt        = true
  }
}
