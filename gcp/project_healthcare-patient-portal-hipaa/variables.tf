variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "project_number" {
  description = "The GCP project number for default service account references"
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be deployed"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "organization_name" {
  description = "Name of the healthcare organization"
  type        = string
  default     = "Regional Healthcare Network"
}