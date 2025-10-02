output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.smart_city_vpc.name
}

output "database_connection_name" {
  description = "Connection name for the Cloud SQL instance"
  value       = google_sql_database_instance.traffic_database.connection_name
}

output "database_private_ip" {
  description = "Private IP address of the database"
  value       = google_sql_database_instance.traffic_database.private_ip_address
}

output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic for sensor data"
  value       = google_pubsub_topic.sensor_data_ingestion.name
}

output "static_assets_bucket_name" {
  description = "Name of the static assets storage bucket"
  value       = google_storage_bucket.static_assets.name
}

output "operator_dashboard_instance_name" {
  description = "Name of the operator dashboard compute instance"
  value       = google_compute_instance.operator_dashboard.name
}

output "operator_dashboard_public_ip" {
  description = "Public IP of the operator dashboard"
  value       = google_compute_instance.operator_dashboard.network_interface[0].access_config[0].nat_ip
}

output "api_gateway_url" {
  description = "URL of the public API gateway"
  value       = google_cloud_run_service.public_api_gateway.status[0].url
}

output "cloud_function_name" {
  description = "Name of the traffic data processor function"
  value       = google_cloudfunctions_function.traffic_data_processor.name
}