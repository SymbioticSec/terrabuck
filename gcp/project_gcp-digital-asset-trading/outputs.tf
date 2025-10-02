output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = google_compute_global_forwarding_rule.load_balancer.ip_address
}

output "api_gateway_url" {
  description = "URL of the Cloud Run API Gateway"
  value       = google_cloud_run_service.api_gateway.status[0].url
}

output "database_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = google_sql_database_instance.trading_database.connection_name
}

output "database_private_ip" {
  description = "Private IP address of the database"
  value       = google_sql_database_instance.trading_database.private_ip_address
  sensitive   = true
}

output "redis_host" {
  description = "Redis instance host"
  value       = google_redis_instance.market_data_cache.host
}

output "redis_port" {
  description = "Redis instance port"
  value       = google_redis_instance.market_data_cache.port
}

output "compliance_bucket_name" {
  description = "Name of the compliance storage bucket"
  value       = google_storage_bucket.compliance_storage.name
}

output "trading_engine_instance_group" {
  description = "Trading engine instance group name"
  value       = google_compute_instance_group_manager.trading_engine_cluster.name
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.digital_asset_trading_vpc.name
}

output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.digital_asset_trading_vpc.id
}