variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "db_admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
  default     = "healthcareadmin"
  sensitive   = true
}

variable "db_admin_password" {
  description = "Administrator password for SQL Server"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_admin_password) >= 12
    error_message = "Database password must be at least 12 characters long."
  }
}

variable "publisher_name" {
  description = "Publisher name for API Management"
  type        = string
  default     = "Healthcare Portal Admin"
}

variable "publisher_email" {
  description = "Publisher email for API Management"
  type        = string
  default     = "admin@healthcareportal.com"
}