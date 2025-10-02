output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.autonomous_drone_delivery_vpc.id
}

output "flight_coordination_engine_ip" {
  description = "External IP of the flight coordination engine"
  value       = google_compute_instance.flight_coordination_engine.network_interface[0].access_config[0].nat_ip
}

output "operational_database_connection_name" {
  description = "Connection name for the operational database"
  value       = google_sql_database_instance.operational_database.connection_name
  sensitive   = true
}

output "telemetry_data_lake_bucket" {
  description = "Name of the telemetry data lake bucket"
  value       = google_storage_bucket.telemetry_data_lake.name
}

output "compliance_archive_bucket" {
  description = "Name of the compliance archive bucket"
  value       = google_storage_bucket.compliance_archive.name
}

output "telemetry_ingestion_function_url" {
  description = "URL of the telemetry ingestion function"
  value       = google_cloudfunctions_function.drone_telemetry_ingestion.https_trigger_url
}

output "compliance_reporting_function_url" {
  description = "URL of the compliance reporting function"
  value       = google_cloudfunctions_function.compliance_reporting_service.https_trigger_url
}

output "delivery_tracking_api_url" {
  description = "URL of the delivery tracking API"
  value       = google_cloud_run_service.delivery_tracking_api.status[0].url
}

output "api_load_balancer_ip" {
  description = "IP address of the API load balancer"
  value       = google_compute_global_address.api_lb_ip.address
}

output "service_account_email" {
  description = "Email of the flight coordination service account"
  value       = google_service_account.flight_coordination_sa.email
}