output "ingestion_gateway_url" {
  description = "URL of the data ingestion gateway"
  value       = google_cloud_run_service.data_ingestion_gateway.status[0].url
}

output "dashboard_instance_ip" {
  description = "Internal IP address of the dashboard instance"
  value       = google_compute_instance.dashboard_application.network_interface[0].network_ip
}

output "analytics_database_connection_name" {
  description = "Connection name for the analytics database"
  value       = google_sql_database_instance.analytics_database.connection_name
}

output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic for event streaming"
  value       = google_pubsub_topic.event_streaming_pipeline.name
}

output "bigquery_dataset_id" {
  description = "ID of the BigQuery dataset"
  value       = google_bigquery_dataset.data_warehouse.dataset_id
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.ecommerce_analytics_vpc.name
}

output "cloud_function_name" {
  description = "Name of the analytics processor Cloud Function"
  value       = google_cloudfunctions_function.analytics_processor.name
}