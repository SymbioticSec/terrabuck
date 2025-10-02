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
  description = "The GCP zone for compute instances"
  type        = string
  default     = "us-central1-a"
}

variable "db_password" {
  description = "Password for the trading database user"
  type        = string
  sensitive   = true
}

variable "organization_domain" {
  description = "Organization domain for user IAM bindings"
  type        = string
  default     = "example.com"
}