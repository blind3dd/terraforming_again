# AWS Provider Configuration
# Configure AWS provider with multiple regions and profiles

# Default AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != null ? var.aws_profile : null

  default_tags {
    tags = {
      Environment = var.environment
      Service     = var.service_name
      ManagedBy   = "Terraform"
      Project     = var.project_name != null ? var.project_name : "database-ci"
    }
  }
}

# AWS Provider for us-west-2 (if needed for multi-region)
provider "aws" {
  alias   = "us_west_2"
  region  = "us-west-2"
  profile = var.aws_profile != null ? var.aws_profile : null

  default_tags {
    tags = {
      Environment = var.environment
      Service     = var.service_name
      ManagedBy   = "Terraform"
      Project     = var.project_name != null ? var.project_name : "database-ci"
    }
  }
}

# AWS Provider for eu-west-1 (if needed for multi-region)
provider "aws" {
  alias   = "eu_west_1"
  region  = "eu-west-1"
  profile = var.aws_profile != null ? var.aws_profile : null

  default_tags {
    tags = {
      Environment = var.environment
      Service     = var.service_name
      ManagedBy   = "Terraform"
      Project     = var.project_name != null ? var.project_name : "database-ci"
    }
  }
}
