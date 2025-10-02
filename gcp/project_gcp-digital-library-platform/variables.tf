variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
  default     = "gcp-digital-library-platform"
}

variable "region" {
  description = "The GCP region where resources will be created"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone where zonal resources will be created"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "university_domain" {
  description = "University domain for authorized users"
  type        = string
  default     = "university.edu"
}

variable "database_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "cloud_run_cpu_limit" {
  description = "CPU limit for Cloud Run services"
  type        = string
  default     = "1000m"
}

variable "cloud_run_memory_limit" {
  description = "Memory limit for Cloud Run services"
  type        = string
  default     = "512Mi"
}

variable "function_memory" {
  description = "Memory allocation for Cloud Functions"
  type        = number
  default     = 256
}

variable "function_timeout" {
  description = "Timeout for Cloud Functions in seconds"
  type        = number
  default     = 60
}

variable "storage_lifecycle_age" {
  description = "Age in days for storage lifecycle management"
  type        = number
  default     = 365
}

variable "logs_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 2555
}