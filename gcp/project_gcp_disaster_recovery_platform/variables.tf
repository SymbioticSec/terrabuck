variable "project_id" {
  description = "The GCP project ID for the disaster recovery platform"
  type        = string
}

variable "primary_region" {
  description = "Primary region for disaster recovery platform deployment"
  type        = string
  default     = "us-central1"
}

variable "secondary_region" {
  description = "Secondary region for disaster recovery replication"
  type        = string
  default     = "us-east1"
}

variable "db_password" {
  description = "Password for the recovery database admin user"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "backup_retention_days" {
  description = "Number of days to retain backup data"
  type        = number
  default     = 90
}

variable "monitoring_enabled" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the platform"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}