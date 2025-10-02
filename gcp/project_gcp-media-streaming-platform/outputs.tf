output "content_storage_bucket" {
  description = "Name of the content storage bucket"
  value       = google_storage_bucket.content_storage.name
}

output "transcoded_storage_bucket" {
  description = "Name of the transcoded content storage bucket"
  value       = google_storage_bucket.transcoded_storage.name
}

output "streaming_api_external_ip" {
  description = "External IP address of the streaming API instance"
  value       = google_compute_instance.streaming_api.network_interface[0].access_config[0].nat_ip
}

output "database_connection_name" {
  description = "Connection name for the Cloud SQL instance"
  value       = google_sql_database_instance.user_database.connection_name
}

output "database_private_ip" {
  description = "Private IP address of the database"
  value       = google_sql_database_instance.user_database.private_ip_address
}

output "analytics_topic_name" {
  description = "Name of the analytics Pub/Sub topic"
  value       = google_pubsub_topic.analytics_pipeline.name
}

output "cdn_global_ip" {
  description = "Global IP address for CDN"
  value       = google_compute_global_forwarding_rule.cdn_distribution.ip_address
}

output "transcoding_function_name" {
  description = "Name of the transcoding Cloud Function"
  value       = google_cloudfunctions_function.transcoding_service.name
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.media_streaming_vpc.name
}

output "ssl_certificate_name" {
  description = "Name of the managed SSL certificate"
  value       = google_compute_managed_ssl_certificate.cdn_ssl_cert.name
}