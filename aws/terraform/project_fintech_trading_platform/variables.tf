variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_app_subnet_cidr" {
  description = "CIDR block for private application subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_data_subnet_cidr" {
  description = "CIDR block for private data subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "trading_engine_instance_type" {
  description = "EC2 instance type for trading engines"
  type        = string
  default     = "c5.xlarge"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r5.large"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "trading_admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}