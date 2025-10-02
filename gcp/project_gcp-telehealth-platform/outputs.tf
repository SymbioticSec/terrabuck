output "patient_portal_load_balancer_ip" {
  description = "External IP address of the patient portal load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "appointment_api_url" {
  description = "URL of the appointment API Cloud Run service"
  value       = google_cloud_run_service.appointment_api.status[0].url
}

output "video_service_url" {
  description = "URL of the video service Cloud Run service"
  value       = google_cloud_run_service.video_service.status[0].url
}

output "database_connection_name" {
  description = "Connection name for the patient database"
  value       = google_sql_database_instance.patient_database.connection_name
}

output "medical_records_bucket_name" {
  description = "Name of the medical records storage bucket"
  value       = google_storage_bucket.medical_records_storage.name
}

output "audit_logs_bucket_name" {
  description = "Name of the audit logs storage bucket"
  value       = google_storage_bucket.audit_logs_bucket.name
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.telehealth_vpc.name
}

output "dns_zone_name_servers" {
  description = "Name servers for the DNS managed zone"
  value       = google_dns_managed_zone.telehealth_zone.name_servers
}