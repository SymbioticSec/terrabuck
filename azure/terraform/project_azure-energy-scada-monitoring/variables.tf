variable "location" {
  description = "Azure region for deploying SCADA monitoring infrastructure"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "production"
}

variable "security_contact_email" {
  description = "Email address for security center notifications"
  type        = string
  default     = "scada-security@gridoperations.com"
}

variable "iot_device_count" {
  description = "Expected number of SCADA devices to connect"
  type        = number
  default     = 10000
}

variable "retention_days" {
  description = "Data retention period in days for compliance"
  type        = number
  default     = 2555
}

variable "allowed_ip_ranges" {
  description = "IP ranges allowed to access SCADA systems"
  type        = list(string)
  default     = ["10.0.0.0/8", "192.168.0.0/16"]
}