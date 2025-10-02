output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.mes_vpc.id
}

output "sensor_data_topic_name" {
  description = "Name of the sensor data Pub/Sub topic"
  value       = google_pubsub_topic.sensor_data_ingestion.name
}

output "production_database_connection_name" {
  description = "Connection name for the production database"
  value       = google_sql_database_instance.production_database.connection_name
}

output "production_database_ip" {
  description = "IP address of the production database"
  value       = google_sql_database_instance.production_database.ip_address
}

output "time_series_storage_bucket" {
  description = "Name of the time series storage bucket"
  value       = google_storage_bucket.time_series_storage.name
}

output "mes_application_external_ip" {
  description = "External IP address of the MES application instance"
  value       = google_compute_instance.mes_application.network_interface[0].access_config[0].nat_ip
}

output "mes_application_internal_ip" {
  description = "Internal IP address of the MES application instance"
  value       = google_compute_instance.mes_application.network_interface[0].network_ip
}

output "data_processing_function_name" {
  description = "Name of the data processing Cloud Function"
  value       = google_cloudfunctions_function.data_processing_pipeline.name
}

output "reporting_function_name" {
  description = "Name of the reporting Cloud Function"
  value       = google_cloudfunctions_function.reporting_service.name
}

output "service_account_email" {
  description = "Email of the service account used by functions"
  value       = google_service_account.function_service_account.email
}