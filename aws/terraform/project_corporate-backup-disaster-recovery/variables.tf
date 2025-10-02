variable "primary_region" {
  description = "Primary AWS region for backup infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "Disaster recovery AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "data_subnet_cidr" {
  description = "CIDR block for the data subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for backup gateway"
  type        = string
  default     = "t3.medium"
}

variable "db_instance_class" {
  description = "RDS instance class for backup metadata database"
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "Username for the backup metadata database"
  type        = string
  default     = "backup_admin"
  sensitive   = true
}

variable "db_password" {
  description = "Password for the backup metadata database"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}