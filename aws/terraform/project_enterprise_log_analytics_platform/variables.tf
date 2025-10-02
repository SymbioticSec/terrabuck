variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_az1" {
  description = "CIDR block for public subnet in AZ1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr_az1" {
  description = "CIDR block for private subnet in AZ1"
  type        = string
  default     = "10.0.2.0/24"
}

variable "data_subnet_cidr_az1" {
  description = "CIDR block for data subnet in AZ1"
  type        = string
  default     = "10.0.3.0/24"
}

variable "elasticsearch_instance_type" {
  description = "Instance type for Elasticsearch cluster"
  type        = string
  default     = "t3.small.elasticsearch"
}

variable "dashboard_instance_type" {
  description = "Instance type for dashboard server"
  type        = string
  default     = "t3.medium"
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = "admin@company.com"
}