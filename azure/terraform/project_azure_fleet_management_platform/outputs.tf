output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.fleet_management.name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway_pip.ip_address
}

output "web_app_url" {
  description = "URL of the fleet management web application"
  value       = "https://${azurerm_linux_web_app.fleet_management_webapp.default_hostname}"
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.fleet_database_server.fully_qualified_domain_name
}

output "eventhub_namespace_name" {
  description = "Name of the Event Hub namespace for telemetry ingestion"
  value       = azurerm_eventhub_namespace.vehicle_telemetry.name
}

output "storage_account_name" {
  description = "Name of the storage account for map tiles"
  value       = azurerm_storage_account.map_tile_storage.name
}

output "function_app_name" {
  description = "Name of the Function App for telemetry processing"
  value       = azurerm_linux_function_app.telemetry_processor.name
}

output "cdn_endpoint_url" {
  description = "CDN endpoint URL for map tiles"
  value       = "https://${azurerm_cdn_endpoint.map_tiles_endpoint.fqdn}"
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.fleet_vnet.id
}

output "database_connection_string" {
  description = "Connection string for the fleet database"
  value       = "Server=${azurerm_mssql_server.fleet_database_server.fully_qualified_domain_name};Database=${azurerm_mssql_database.fleet_database.name};User Id=${var.sql_admin_username};Password=<password>;"
  sensitive   = true
}