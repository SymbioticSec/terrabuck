output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.multi_location_restaurant_pos_system_cluster_pos_application.name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.multi_location_restaurant_pos_system_cluster_pos_application.endpoint
  sensitive   = true
}

output "database_connection_name" {
  description = "Cloud SQL connection name"
  value       = google_sql_database_instance.multi_location_restaurant_pos_system_database_pos.connection_name
}

output "database_private_ip" {
  description = "Cloud SQL private IP address"
  value       = google_sql_database_instance.multi_location_restaurant_pos_system_database_pos.private_ip_address
}

output "inventory_bucket_name" {
  description = "Name of the inventory storage bucket"
  value       = google_storage_bucket.multi_location_restaurant_pos_system_bucket_inventory.name
}

output "payment_processor_url" {
  description = "URL of the payment processing Cloud Function"
  value       = google_cloudfunctions_function.multi_location_restaurant_pos_system_function_payment_processor.https_trigger_url
  sensitive   = true
}

output "load_balancer_ip" {
  description = "External IP address of the load balancer"
  value       = google_compute_global_address.multi_location_restaurant_pos_system_address_lb.address
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.multi_location_restaurant_pos_system_vpc_main.name
}

output "ssl_certificate_name" {
  description = "Name of the managed SSL certificate"
  value       = google_compute_managed_ssl_certificate.multi_location_restaurant_pos_system_cert_ssl.name
}

output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = google_kms_crypto_key.multi_location_restaurant_pos_system_key_storage.id
}