terraform {
  required_providers {
      azurerm = {
        source = "hashicorp/azurerm"
        version = "~>2.0"
      }
    }
    backend "azure" {
      resource_group_name = "velidarg"
      storage_account_name = "velidaterraform"
      container_name = "myhealthdbsinkactivitytfstate"
      key = "terraform.tfstate"
    }
}

provider "azurerm" {
  features {}
}

module "resource_group" {
    source = "../../modules/resource_group"
    resource_group_name = var.resource_group_name
    resource_group_location = var.resource_group_location
    resource_group_tags = {
        "Terraform" = "true"
        "Resource-Specific" = "false"
        "ApplicationName" = "MyHealth"
        "ServiceName" = "MyHealth.DBSink.Activity"
    }  
}

# Import Key Vault
data "azurerm_key_vault" "velidakeyvault" {
    name = var.velida_key_vault
    resource_group_name = var.velida_resource_group_name
}

# Import App Config
data "azurerm_app_configuration" "appconfig" {
  name = var.appconfig_name
  resource_group_name = var.appconfig_rg
} 

# Import App Service Plan
data "azurerm_app_service_plan" "appplan" {
    name = var.myhealth_app_service_plan
    resource_group_name = var.myhealth_app_resource_group
}

# Import Cosmos DB
data "azurerm_cosmosdb_account" "cosmosdb" {
  name = var.myhealth_cosmos_name
  resource_group_name = var.myhealth_cosmos_resource_group
}

# Create storage account for MyHealth.FileValidator.Activity
module "storage_account" {
    source = "../../modules/storage_account"
    storage_account_name = var.function_storage_name
    resource_group_name = module.resource_group.name
    storage_location = module.resource_group.location
    account_tier = "Standard"
    account_replication_type = "LRS"
    account_kind = "StorageV2"
    is_hns_enabled = "false"
}

# Create Function App for MyHealth.DBSink.Activity
resource "azurerm_function_app" "myhealthactivity" {
  name = var.myhealth_dbsink_activity_function_name
  location = module.resource_group.location
  resource_group_name = module.resource_group.name
  app_service_plan_id = data.azurerm_app_service_plan.appplan.id
  storage_account_name = module.storage_account.storage_account_name
  storage_account_access_key = module.storage_account.primary_access_key
  os_type = "linux"
  version = "~3"

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [app_settings]
  }
}

# Create Key Vault Access Policy for Key Vault
resource "azurerm_key_vault_access_policy" "velidakeyvault_policy" {
  key_vault_id = data.azurerm_key_vault.velidakeyvault.id
  tenant_id = var.tenant_id
  object_id = azurerm_function_app.myhealthactivity.identity[0].principal_id
  secret_permissions = [ "get","list" ]
}

resource "azurerm_role_assignment" "appconfigrole" {
  scope = data.azurerm_app_configuration.appconfig.id
  role_definition_name = "App Configuration Data Reader"
  principal_id = azurerm_function_app.myhealthactivity.identity[0].principal_id
}

resource "azurerm_role_assignment" "cosmosdbrole" {
  scope = data.azurerm_cosmosdb_account.cosmosdb.id
  role_definition_name = "DocumentDB Account Contributor"
  principal_id = azurerm_function_app.myhealthactivity.identity[0].principal_id
}