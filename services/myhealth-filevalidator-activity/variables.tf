variable "resource_group_name" {
  default = "myhealthfilevalidatoractivity-rg"
}

variable "resource_group_location" {
  default = "australiaeast"
}

variable "velida_key_vault" {
  default = "willvelidakeyvault"
}

variable "velida_resource_group_name" {
  default = "velidaazureengine-rg"
}

variable "myhealth_app_service_plan" {
  default = "myhealthappserviceplan"
  description = "Name of the App Service Plan for MyHealth"
  type = string
}

variable "myhealth_resource_group" {
  default = "myhealth-rg"
  description = "The name of the resource group for MyHealth"
  type = string
}

variable "function_storage_name" {
  default = "samyhealthfvactivity"
  description = "Name of the storage account for MyHealth.FileValidator.Activity"
  type = string
}

variable "myhealth_filevalidator_activity_function_name" {
  default = "famyhealthfilevalidatoractivity"
  description = "Name of the MyHealth.FileValidator.Activity App"
  type = string
}