# Google Cloud Provider Configuration
# Configure GCP provider with multiple projects

# Default GCP Provider
provider "google" {
  project = var.gcp_project_id != null ? var.gcp_project_id : null
  region  = var.gcp_region != null ? var.gcp_region : null
  zone    = var.gcp_zone != null ? var.gcp_zone : null
}

# GCP Provider for different project (if needed)
provider "google" {
  alias   = "secondary"
  project = var.gcp_secondary_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}
