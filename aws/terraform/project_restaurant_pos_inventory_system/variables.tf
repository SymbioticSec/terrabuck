variable "aws_region" {
  description = "AWS region for restaurant POS infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
  default     = "10.0.10.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
  default     = "10.0.20.0/24"
}

variable "data_subnet_1_cidr" {
  description = "CIDR block for data subnet 1"
  type        = string
  default     = "10.0.100.0/24"
}

variable "data_subnet_2_cidr" {
  description = "CIDR block for data subnet 2"
  type        = string
  default     = "10.0.200.0/24"
}

variable "pos_instance_type" {
  description = "Instance type for POS application servers"
  type        = string
  default     = "t3.medium"
}

variable "db_instance_class" {
  description = "RDS instance class for inventory database"
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "Username for the inventory database"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Password for the inventory database"
  type        = string
  default     = "RestaurantPOS123!"
  sensitive   = true
}

variable "cache_node_type" {
  description = "Node type for ElastiCache Redis cluster"
  type        = string
  default     = "cache.t3.micro"
}