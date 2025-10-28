# Azure Provider Configuration
# Configure Azure provider with multiple subscriptions

# Default Azure Provider
provider "azurerm" {
  features {}
  
  subscription_id = var.azure_subscription_id != null ? var.azure_subscription_id : null
  tenant_id       = var.azure_tenant_id != null ? var.azure_tenant_id : null
  client_id       = var.azure_client_id != null ? var.azure_client_id : null
  client_secret   = var.azure_client_secret != null ? var.azure_client_secret : null
}

# Azure Provider for different subscription (if needed)
provider "azurerm" {
  alias = "secondary"
  features {}
  
  subscription_id = var.azure_secondary_subscription_id
  tenant_id       = var.azure_tenant_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
}
