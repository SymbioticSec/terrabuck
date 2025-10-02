output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.trading_platform_vpc.id
}

output "trading_database_connection_name" {
  description = "Connection name for the trading database"
  value       = google_sql_database_instance.trading_database.connection_name
}

output "trading_database_private_ip" {
  description = "Private IP address of the trading database"
  value       = google_sql_database_instance.trading_database.private_ip_address
}

output "market_data_storage_bucket" {
  description = "Name of the market data storage bucket"
  value       = google_storage_bucket.market_data_storage.name
}

output "trading_engine_instance_id" {
  description = "ID of the trading engine compute instance"
  value       = google_compute_instance.trading_engine.id
}

output "market_data_ingester_url" {
  description = "URL of the market data ingester Cloud Run service"
  value       = google_cloud_run_service.market_data_ingester.status[0].url
}

output "risk_manager_function_name" {
  description = "Name of the risk manager Cloud Function"
  value       = google_cloudfunctions_function.risk_manager.name
}

output "market_data_topic_name" {
  description = "Name of the market data Pub/Sub topic"
  value       = google_pubsub_topic.market_data_topic.name
}

output "trade_signals_topic_name" {
  description = "Name of the trade signals Pub/Sub topic"
  value       = google_pubsub_topic.trade_signals_topic.name
}

output "vpc_connector_name" {
  description = "Name of the VPC access connector"
  value       = google_vpc_access_connector.trading_connector.name
}