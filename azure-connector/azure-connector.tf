# Azure Connector for Hybrid Cloud Architecture
# Integrates with existing AWS infrastructure

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Azure Provider Configuration
provider "azurerm" {
  features {}
}

# AWS Provider Configuration (for cross-cloud integration)
provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region for cross-cloud integration"
  type        = string
  default     = "us-west-2"
}

variable "azure_location" {
  description = "Azure location for resources"
  type        = string
  default     = "West US 2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "hybrid"
}

# Resource Group
resource "azurerm_resource_group" "hybrid" {
  name     = "${var.environment}-hybrid-rg"
  location = var.azure_location

  tags = {
    Environment = var.environment
    Project     = "database_CI"
    ManagedBy   = "Terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "hybrid" {
  name                = "${var.environment}-hybrid-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.hybrid.location
  resource_group_name = azurerm_resource_group.hybrid.name

  tags = {
    Environment = var.environment
    Project     = "database_CI"
  }
}

# Subnet for Azure resources
resource "azurerm_subnet" "hybrid" {
  name                 = "${var.environment}-hybrid-subnet"
  resource_group_name  = azurerm_resource_group.hybrid.name
  virtual_network_name = azurerm_virtual_network.hybrid.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "hybrid" {
  name                = "${var.environment}-hybrid-nsg"
  location            = azurerm_resource_group.hybrid.location
  resource_group_name = azurerm_resource_group.hybrid.name

  # Allow SSH from AWS VPC
  security_rule {
    name                       = "SSH-from-AWS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.0.0/16"  # AWS VPC CIDR
    destination_address_prefix = "*"
  }

  # Allow HTTPS
  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTP only from specific sources (restricted from internet)
  security_rule {
    name                       = "HTTP-restricted"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.0.0/16"  # Only from AWS VPC
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = "database_CI"
  }
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "hybrid" {
  subnet_id                 = azurerm_subnet.hybrid.id
  network_security_group_id = azurerm_network_security_group.hybrid.id
}

# Azure Container Registry
resource "azurerm_container_registry" "hybrid" {
  name                = "${var.environment}hybridacr"
  resource_group_name = azurerm_resource_group.hybrid.name
  location            = azurerm_resource_group.hybrid.location
  sku                 = "Premium"  # Required for geo-replication and zone redundancy
  admin_enabled       = false      # CKV_AZURE_137: Disable admin account
  public_network_access_enabled = false  # CKV_AZURE_139: Disable public networking
  zone_redundancy_enabled = true   # CKV_AZURE_233: Enable zone redundancy

  # CKV_AZURE_164: Enable trusted image scanning
  trust_policy {
    enabled = true
  }

  # CKV_AZURE_166: Enable image quarantine and scanning
  quarantine_policy_enabled = true
  retention_policy {
    enabled = true
    days    = 7  # CKV_AZURE_167: Set retention policy for untagged manifests
  }

  # CKV_AZURE_165: Enable geo-replication (requires Premium SKU)
  georeplications {
    location                = "East US"
    zone_redundancy_enabled = true
    tags = {
      Environment = var.environment
      Project     = "database_CI"
    }
  }

  # CKV_AZURE_237: Enable dedicated data endpoints
  data_endpoint_enabled = true

  tags = {
    Environment = var.environment
    Project     = "database_CI"
  }
}

# Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "hybrid" {
  name                = "${var.environment}-hybrid-aks"
  location            = azurerm_resource_group.hybrid.location
  resource_group_name = azurerm_resource_group.hybrid.name
  dns_prefix          = "${var.environment}-hybrid-aks"
  kubernetes_version  = "1.28"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  # Enable Azure AD integration
  azure_active_directory_role_based_access_control {
    managed = true
    azure_rbac_enabled = true
  }

  # Network profile
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"  # CKV_AZURE_7: Enable Network Policy
    service_cidr   = "10.2.0.0/24"
    dns_service_ip = "10.2.0.10"
  }

  tags = {
    Environment = var.environment
    Project     = "database_CI"
  }
}

# Azure Key Vault for secrets
resource "azurerm_key_vault" "hybrid" {
  name                = "${var.environment}-hybrid-kv"
  location            = azurerm_resource_group.hybrid.location
  resource_group_name = azurerm_resource_group.hybrid.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Enable soft delete
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Access policy for current user
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover", "Purge"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover", "Purge"
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover", "Purge"
    ]
  }

  tags = {
    Environment = var.environment
    Project     = "database_CI"
  }
}

# Data source for current Azure client
data "azurerm_client_config" "current" {}

# Azure Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "hybrid" {
  name                = "${var.environment}-hybrid-law"
  location            = azurerm_resource_group.hybrid.location
  resource_group_name = azurerm_resource_group.hybrid.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Project     = "database_CI"
  }
}

# Azure Monitor
resource "azurerm_monitor_diagnostic_setting" "hybrid" {
  name                       = "${var.environment}-hybrid-monitor"
  target_resource_id         = azurerm_kubernetes_cluster.hybrid.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hybrid.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
  }
}

# Outputs
output "azure_resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.hybrid.name
}

output "azure_vnet_id" {
  description = "ID of the Azure virtual network"
  value       = azurerm_virtual_network.hybrid.id
}

output "azure_aks_cluster_name" {
  description = "Name of the Azure Kubernetes Service cluster"
  value       = azurerm_kubernetes_cluster.hybrid.name
}

output "azure_aks_kube_config" {
  description = "Kubeconfig for the Azure Kubernetes Service cluster"
  value       = azurerm_kubernetes_cluster.hybrid.kube_config_raw
  sensitive   = true
}

output "azure_acr_login_server" {
  description = "Login server for the Azure Container Registry"
  value       = azurerm_container_registry.hybrid.login_server
}

output "azure_key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = azurerm_key_vault.hybrid.vault_uri
}

output "azure_log_analytics_workspace_id" {
  description = "ID of the Azure Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.hybrid.workspace_id
}
