variable "project_id" {
  description = "The GCP project ID for the restaurant POS system"
  type        = string
}

variable "region" {
  description = "The GCP region for deploying resources"
  type        = string
  default     = "us-central1"
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "pos.restaurant-chain.com"
}

variable "developer_email" {
  description = "Developer email for IAM permissions"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "restaurant_locations" {
  description = "Number of restaurant locations"
  type        = number
  default     = 15
}

variable "gke_node_count" {
  description = "Number of nodes in the GKE cluster"
  type        = number
  default     = 2
}

variable "database_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "enable_monitoring" {
  description = "Enable monitoring and logging"
  type        = bool
  default     = true
}