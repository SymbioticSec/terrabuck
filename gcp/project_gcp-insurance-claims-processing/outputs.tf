output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.claims_vpc.id
}

output "claims_database_connection_name" {
  description = "Connection name for the claims database"
  value       = google_sql_database_instance.claims_database.connection_name
}

output "claims_database_private_ip" {
  description = "Private IP address of the claims database"
  value       = google_sql_database_instance.claims_database.private_ip_address
}

output "claims_documents_bucket_name" {
  description = "Name of the claims documents storage bucket"
  value       = google_storage_bucket.claims_documents.name
}

output "claims_processing_engine_internal_ip" {
  description = "Internal IP address of the claims processing engine"
  value       = google_compute_instance.claims_processing_engine.network_interface[0].network_ip
}

output "document_analysis_function_name" {
  description = "Name of the document analysis Cloud Function"
  value       = google_cloudfunctions_function.document_analysis.name
}

output "fraud_detection_service_url" {
  description = "URL of the fraud detection Cloud Run service"
  value       = google_cloud_run_service.fraud_detection.status[0].url
}

output "notification_topic_name" {
  description = "Name of the notification Pub/Sub topic"
  value       = google_pubsub_topic.notification_queue.name
}

output "api_gateway_ip_address" {
  description = "Global IP address for the API gateway"
  value       = google_compute_global_address.api_gateway_ip.address
}

output "vpc_connector_name" {
  description = "Name of the VPC access connector"
  value       = google_vpc_access_connector.connector.name
}

output "private_subnet_cidr" {
  description = "CIDR range of the private subnet"
  value       = google_compute_subnetwork.private_subnet.ip_cidr_range
}

output "audit_logs_bucket_name" {
  description = "Name of the audit logs storage bucket"
  value       = google_storage_bucket.audit_logs.name
}