output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.carbon_tracking_vpc.name
}

output "emissions_data_lake_bucket" {
  description = "Name of the emissions data lake storage bucket"
  value       = google_storage_bucket.emissions_data_lake.name
}

output "reports_storage_bucket" {
  description = "Name of the reports storage bucket"
  value       = google_storage_bucket.reports_storage.name
}

output "carbon_calculation_instances" {
  description = "Names of carbon calculation compute instances"
  value       = google_compute_instance.carbon_calculation_engine[*].name
}

output "reporting_database_connection_name" {
  description = "Connection name for the reporting database"
  value       = google_sql_database_instance.reporting_database.connection_name
}

output "reporting_database_private_ip" {
  description = "Private IP address of the reporting database"
  value       = google_sql_database_instance.reporting_database.private_ip_address
}

output "iot_ingestion_function_url" {
  description = "URL of the IoT data ingestion Cloud Function"
  value       = google_cloudfunctions_function.iot_data_ingestion.https_trigger_url
}

output "report_generation_service_url" {
  description = "URL of the report generation Cloud Run service"
  value       = google_cloud_run_service.report_generation_service.status[0].url
}

output "app_engine_url" {
  description = "URL of the App Engine sustainability dashboard"
  value       = "https://${var.project_id}.appspot.com"
}

output "kms_key_id" {
  description = "ID of the KMS encryption key"
  value       = google_kms_crypto_key.storage_key.id
}