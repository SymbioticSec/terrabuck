variable "resource_group_name" {
  description = "Name of the resource group for the corporate media streaming platform"
  type        = string
  default     = "rg-corporate-media-streaming-platform"
}

variable "location" {
  description = "Azure region for deploying resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "production"
}

variable "sql_admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
  default     = "sqladmin"
  sensitive   = true
}

variable "sql_admin_password" {
  description = "Administrator password for SQL Server"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.sql_admin_password) >= 8
    error_message = "SQL admin password must be at least 8 characters long."
  }
}