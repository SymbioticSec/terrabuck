variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the IoT analytics platform project"
  type        = string
  default     = "smart-manufacturing-iot-analytics-platform"
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

variable "kinesis_shard_count" {
  description = "Number of shards for Kinesis data stream"
  type        = number
  default     = 2
}