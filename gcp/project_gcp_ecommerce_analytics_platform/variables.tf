variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for compute resources"
  type        = string
  default     = "us-central1-a"
}

variable "db_password" {
  description = "Password for the analytics database user"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "Email address of the administrator for BigQuery access"
  type        = string
}

variable "organization_domain" {
  description = "Organization domain for BigQuery access"
  type        = string
}