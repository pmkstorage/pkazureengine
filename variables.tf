variable "resource_group_name" {
  description = "Name of the resource group"
  type = string
  default = "velidaazureengine-rg"
}

variable "resource_group_location" {
  description = "Location of the resource group"
  type = string
  default = "australiaeast"
}

variable "cosmos_failover_location" {
  description = "Cosmos DB Failover location"
  type = string
  default = "australiasoutheast"
}

variable "cosmos_account_name" {
  description = "Name of the Cosmos DB account"
  type = string
  default = "willvelidacosmosdb"
}

variable "storage_account_name" {
  default = "velidastorage"
  description = "Name of the Storage account"
  type = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault"
  default = "willvelidakeyvault"
  type = string
}

variable "log_analytics_name" {
  description = "Name of the Log Analytics"
  default = "velidaloganalytics"
  type = string
}

variable "cosmos_log_analytic_setting" {
  description = "Name of the diagnostic log settings for Cosmos DB"
  default = "cosmosdb_loganalytics_diagnostic_settings"
  type = string
}

variable "api_management_name" {
  description = "Name of the API Management Instance"
  default = "velidaapimanagement"
  type = string
}

variable "cosmos_db_connection_string_secret" {
  default = "cosmosdbconnectionstring"
  description = "Name of the secret for the Cosmos DB Connection String"
  type = string
}

variable "azure_storage_connection_string_secret" {
  default = "azurestorageconnectionstring"
  description = "Name of the secret for the connection string to Azure Blob Storage"
  type = string
}

variable "azure_storage_primary_access_key_secret" {
  default = "azurestorageprimaryaccesskey"
  description = "Name of the secret for the primary access key to Azure Blob Storage"
  type = string
}

variable "service_bus_namespace_name" {
  default = "velidaservicebus"
  description = "Name of the Service Bus Namespace"
  type = string
}

variable "my_health_files_container_name" {
  default = "myhealthfiles"
  description = "Name of the container to hold all my health files"
  type = string
}

variable "app_insights_name" {
  default = "velidaapplicationinsights"
  type = string
}

variable "key_vault_logs" {
  default = "velidakeyvaultlogs"
  type = string
}