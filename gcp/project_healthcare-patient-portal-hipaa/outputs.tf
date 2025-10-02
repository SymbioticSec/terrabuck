output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = google_compute_global_forwarding_rule.load_balancer.ip_address
}

output "database_connection_name" {
  description = "Connection name for the Cloud SQL instance"
  value       = google_sql_database_instance.patient_database.connection_name
  sensitive   = true
}

output "document_storage_bucket" {
  description = "Name of the document storage bucket"
  value       = google_storage_bucket.document_storage.name
}

output "audit_logs_bucket" {
  description = "Name of the audit logs storage bucket"
  value       = google_storage_bucket.audit_logs.name
}

output "kms_key_id" {
  description = "ID of the KMS encryption key"
  value       = google_kms_crypto_key.hipaa_key.id
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.hipaa_vpc.name
}

output "web_instance_group" {
  description = "Web frontend instance group"
  value       = google_compute_region_instance_group_manager.web_frontend.instance_group
}

output "api_instance_group" {
  description = "API backend instance group"
  value       = google_compute_region_instance_group_manager.api_backend.instance_group
}

output "service_account_email" {
  description = "Email of the application service account"
  value       = google_service_account.app_service_account.email
}