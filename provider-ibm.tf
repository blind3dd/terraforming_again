# IBM Cloud Provider Configuration
# Configure IBM Cloud provider

# Default IBM Cloud Provider
provider "ibm" {
  ibmcloud_api_key = var.ibm_cloud_api_key
  region           = var.ibm_region
  zone             = var.ibm_zone
}
