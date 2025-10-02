variable "project_name" {
  description = "Name of the disaster recovery platform project"
  type        = string
  default     = "drplatform"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "primary_location" {
  description = "Primary Azure region for disaster recovery platform"
  type        = string
  default     = "East US"
}

variable "secondary_location" {
  description = "Secondary Azure region for disaster recovery replication"
  type        = string
  default     = "West US 2"
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

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Project     = "Enterprise Disaster Recovery Platform"
    Environment = "Production"
    Owner       = "DR Team"
    CostCenter  = "IT-Infrastructure"
    Compliance  = "SOX-GDPR"
  }
}