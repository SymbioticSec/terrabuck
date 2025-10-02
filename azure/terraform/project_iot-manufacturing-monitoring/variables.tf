variable "resource_group_name" {
  description = "Name of the resource group for the smart manufacturing IoT platform"
  type        = string
  default     = "rg-smart-manufacturing-iot-monitoring-platform"
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "production"
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = "manufacturing-ops-team"
}

variable "storage_account_name" {
  description = "Name of the storage account for blob storage"
  type        = string
  default     = "smartmfgiotblob001"
}

variable "function_storage_account_name" {
  description = "Name of the storage account for function app"
  type        = string
  default     = "smartmfgiotfunc001"
}

variable "kusto_cluster_name" {
  description = "Name of the Azure Data Explorer cluster"
  type        = string
  default     = "smartmfgiotkusto001"
}