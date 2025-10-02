output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.digital_library_vpc.id
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.digital_library_vpc.name
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = google_compute_subnetwork.public_subnet.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = google_compute_subnetwork.private_subnet.id
}

output "data_subnet_id" {
  description = "ID of the data subnet"
  value       = google_compute_subnetwork.data_subnet.id
}

output "content_storage_bucket_name" {
  description = "Name of the content storage bucket"
  value       = google_storage_bucket.content_storage.name
}

output "content_storage_bucket_url" {
  description = "URL of the content storage bucket"
  value       = google_storage_bucket.content_storage.url
}

output "usage_logs_bucket_name" {
  description = "Name of the usage logs storage bucket"
  value       = google_storage_bucket.usage_logs.name
}

output "user_database_connection_name" {
  description = "Connection name for the user database"
  value       = google_sql_database_instance.user_database.connection_name
}

output "user_database_ip_address" {
  description = "IP address of the user database"
  value       = google_sql_database_instance.user_database.ip_address
}

output "metadata_database_connection_name" {
  description = "Connection name for the metadata database"
  value       = google_sql_database_instance.metadata_database.connection_name
}

output "metadata_database_ip_address" {
  description = "IP address of the metadata database"
  value       = google_sql_database_instance.metadata_database.ip_address
}

output "api_gateway_url" {
  description = "URL of the API Gateway Cloud Run service"
  value       = google_cloud_run_service.api_gateway.status[0].url
}

output "search_service_url" {
  description = "URL of the Search Service Cloud Run service"
  value       = google_cloud_run_service.search_service.status[0].url
}

output "analytics_function_name" {
  description = "Name of the analytics processor Cloud Function"
  value       = google_cloudfunctions_function.analytics_processor.name
}

output "api_gateway_service_account_email" {
  description = "Email of the API Gateway service account"
  value       = google_service_account.api_gateway_sa.email
}

output "search_service_account_email" {
  description = "Email of the Search Service service account"
  value       = google_service_account.search_service_sa.email
}

output "analytics_service_account_email" {
  description = "Email of the Analytics Processor service account"
  value       = google_service_account.analytics_processor_sa.email
}

output "ssl_policy_name" {
  description = "Name of the SSL policy"
  value       = google_compute_ssl_policy.api_ssl_policy.name
}