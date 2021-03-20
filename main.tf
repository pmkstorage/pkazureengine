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
    }
  }
}

## Velida Azure Engine Resource Group
resource "azurerm_resource_group" "rg" {
  name = var.resource_group_name
  location = var.resource_group_location
}

## Azure Cosmos DB Account
resource "azurerm_cosmosdb_account" "db" {
  name = var.cosmos_account_name
  location = var.resource_group_location
  resource_group_name = var.resource_group_name
  offer_type = "Standard"
  kind = "GlobalDocumentDB"
  enable_automatic_failover = true
  
  geo_location {
    location = var.resource_group_location
    failover_priority = 0
  }

  geo_location {
    location = var.cosmos_failover_location
    failover_priority = 1
  }

  analytical_storage_enabled = true

  consistency_policy {
    consistency_level = "Session"
  }
}

## Storage Account
resource "azurerm_storage_account" "storage" {
  name = var.storage_account_name
  resource_group_name = var.resource_group_name
  location = var.resource_group_location
  account_tier = "Standard"
  account_replication_type = "GRS"
}

# Key Vault
resource "azurerm_key_vault" "keyvault" {
  name = var.key_vault_name
  location = var.resource_group_location
  resource_group_name = var.resource_group_name
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
      "List"
    ]

    key_permissions = [
      "List",
      "Get",
      "Create"
    ]
  }
}

# Cosmos DB Connection String Secret
resource "azurerm_key_vault_secret" "cosmosdbconnectionstring" {
  name = var.cosmos_db_connection_string_secret
  value = azurerm_cosmosdb_account.db.connection_strings[0]
  key_vault_id = azurerm_key_vault.keyvault.id
}

# Azure Storage Connection String
resource "azurerm_key_vault_secret" "azure_storage_connection_string" {
  name = var.azure_storage_connection_string_secret
  value = azurerm_storage_account.storage.primary_connection_string
  key_vault_id = azurerm_key_vault.keyvault.id
}

# Azure Storage Primary Access Key
resource "azurerm_key_vault_secret" "azure_storage_primary_access" {
  name = var.azure_storage_primary_access_key_secret
  value = azurerm_storage_account.storage.primary_access_key
  key_vault_id = azurerm_key_vault.keyvault.id
}

# Azure Log Analytics
resource "azurerm_log_analytics_workspace" "logs" {
  name = var.log_analytics_name
  location = var.resource_group_location
  resource_group_name = var.resource_group_name
  sku = "PerGB2018"
  retention_in_days = 30
}

# Adding Cosmos DB Metrics to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "cosmosdbdiagnostics" {
  name = var.cosmos_log_analytic_setting
  target_resource_id = azurerm_cosmosdb_account.db.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  log {
    category = "DataPlaneRequests"
  }

  log {
    category = "QueryRuntimeStatistics"
  }

  log {
    category = "PartitionKeyStatistics"
  }

  log {
    category = "PartitionKeyRUConsumption"
  }

  log {
    category = "ControlPlaneRequests"
  }

  metric {
    category = "Requests"
  }
}

## Add API Management
resource "azurerm_api_management" "apiportal" {
  name = var.api_management_name
  location = var.resource_group_location
  resource_group_name = var.resource_group_name
  publisher_name = "Will Velida"
  publisher_email = "willvelida@hotmail.co.uk"

  sku_name = "Developer_1"
}