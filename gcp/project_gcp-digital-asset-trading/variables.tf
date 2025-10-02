variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "trading_engine_machine_type" {
  description = "Machine type for trading engine instances"
  type        = string
  default     = "n2-standard-4"
}

variable "trading_engine_instance_count" {
  description = "Number of trading engine instances"
  type        = number
  default     = 3
}

variable "redis_memory_size" {
  description = "Memory size for Redis instance in GB"
  type        = number
  default     = 4
}

variable "database_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-standard-2"
}

variable "database_user" {
  description = "Database username"
  type        = string
  default     = "trading_user"
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}