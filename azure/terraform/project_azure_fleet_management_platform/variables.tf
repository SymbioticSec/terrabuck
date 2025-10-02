variable "project_name" {
  description = "Name of the fleet management project"
  type        = string
  default     = "fleet-management-gps"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "East US"
}

variable "sql_admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "Administrator password for SQL Server"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Fleet Management Platform"
    Environment = "Development"
    Owner       = "DevOps Team"
    CostCenter  = "Logistics"
  }
}