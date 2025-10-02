output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.fleet_management_vpc.name
}

output "database_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = google_sql_database_instance.fleet_database.connection_name
}

output "telemetry_bucket_name" {
  description = "Name of the telemetry data lake bucket"
  value       = google_storage_bucket.telemetry_data_lake.name
}

output "analytics_bucket_name" {
  description = "Name of the analytics storage bucket"
  value       = google_storage_bucket.analytics_storage.name
}

output "telemetry_function_url" {
  description = "URL of the telemetry ingestion function"
  value       = google_cloudfunctions_function.vehicle_telemetry_ingestion.https_trigger_url
}

output "api_instance_ip" {
  description = "Internal IP of the fleet management API instance"
  value       = google_compute_instance.fleet_management_api.network_interface[0].network_ip
}

output "dashboard_instance_ip" {
  description = "Internal IP of the dispatcher dashboard instance"
  value       = google_compute_instance.dispatcher_dashboard.network_interface[0].network_ip
}

output "dashboard_external_ip" {
  description = "External IP for the dashboard load balancer"
  value       = google_compute_global_address.dashboard_ip.address
}

output "kms_key_id" {
  description = "ID of the KMS encryption key"
  value       = google_kms_crypto_key.telemetry_key.id
}

output "private_subnet_cidr" {
  description = "CIDR range of the private subnet"
  value       = google_compute_subnetwork.private_subnet.ip_cidr_range
}