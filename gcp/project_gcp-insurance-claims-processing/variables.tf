variable "project_id" {
  description = "The GCP project ID for the insurance claims processing platform"
  type        = string
}

variable "project_number" {
  description = "The GCP project number for service account configuration"
  type        = string
}

variable "region" {
  description = "The GCP region for deploying resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for compute instances"
  type        = string
  default     = "us-central1-a"
}

variable "domain" {
  description = "The domain name for user email addresses"
  type        = string
  default     = "example.com"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "claims_processing_machine_type" {
  description = "Machine type for the claims processing engine"
  type        = string
  default     = "e2-medium"
}

variable "database_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "function_memory" {
  description = "Memory allocation for Cloud Functions in MB"
  type        = number
  default     = 256
}

variable "cloud_run_max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 10
}