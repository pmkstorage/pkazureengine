terraform {
    backend "azure" {
      resource_group_name = "velidarg"
      storage_account_name = "velidaterraform"
      container_name = "tstate"
      key = "terraform.tfstate"
    }
}

data "azurerm_client_config" "current" {}

provider "azurerm" {
  version = "~>2.0"
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

## Velida Azure Engine Resource Group
module "resource_group" {
  source = "./modules/resource_group"
  resource_group_name = var.resource_group_name
  resource_group_location = var.resource_group_location
  resource_group_tags = {
    "Terraform" = "true"
    "Environment" = "Dev"
    "MainAzureEngineResource" = "True"
  }
}

## Storage Account
module "storage_account" {
  source = "./modules/storage_account"
  storage_account_name = var.storage_account_name
  resource_group_name = module.resource_group.name
  storage_location = module.resource_group.location
  account_tier = "Standard"
  account_replication_type = "GRS"
  account_kind = "StorageV2"
  is_hns_enabled = "false"
  storage_account_tags = {
    "Environment" = "Dev"
    "MainAzureEngineResource" = "True"
  }
}

module "storage_container" {
  source = "./modules/storage_container"
  storage_container_name = var.my_health_files_container_name
  storage_account_name = module.storage_account.storage_account_name
  container_access_type = "private"
}

## Service Bus
module "service_bus_namespace" {
  source = "./modules/service_bus_namespace"
  service_bus_namespace_name = var.service_bus_namespace_name
  service_bus_namespace_location = module.resource_group.location
  service_bus_resource_group = module.resource_group.name
  service_bus_tags = {
    "Environment" = "Dev"
    "MainAzureEngineResource" = "True"
  }
}

# App Insights
module "app_insights" {
  source = "./modules/app_insights"
  app_insights_name = var.app_insights_name
  app_insights_location = module.resource_group.location
  app_insights_rg = module.resource_group.name
  app_type = "web"
}

# Key Vault
resource "azurerm_key_vault" "keyvault" {
  name = var.key_vault_name
  location = module.resource_group.location
  resource_group_name = module.resource_group.name
  enabled_for_disk_encryption = true
  sku_name = "standard"
  tenant_id = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7

  access_policy  {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "Set",
      "List",
      "Delete",
      "Recover",
      "Purge"
    ]

    key_permissions = [
      "List",
      "Get",
      "Create",
      "Delete",
      "Recover"
    ]
  }
}

# Azure Log Analytics
resource "azurerm_log_analytics_workspace" "logs" {
  name = var.log_analytics_name
  location = module.resource_group.location
  resource_group_name = module.resource_group.name
  sku = "PerGB2018"
  retention_in_days = 30
}

# Enable Logging on Key Vault
resource "azurerm_monitor_diagnostic_setting" "keyvaultlogs" {
  name = var.key_vault_logs
  target_resource_id = azurerm_key_vault.keyvault.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  log {
    category = "AuditEvent"
    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = false
    }
  }
}

# Azure Storage Connection String
resource "azurerm_key_vault_secret" "azure_storage_connection_string" {
  name = var.azure_storage_connection_string_secret
  value = module.storage_account.connection_string
  key_vault_id = azurerm_key_vault.keyvault.id
}

# Azure Storage Primary Access Key
resource "azurerm_key_vault_secret" "azure_storage_primary_access" {
  name = var.azure_storage_primary_access_key_secret
  value = module.storage_account.primary_access_key
  key_vault_id = azurerm_key_vault.keyvault.id
}