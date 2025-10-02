output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.corporate_media_streaming.name
}

output "media_storage_account_name" {
  description = "Name of the media storage account"
  value       = azurerm_storage_account.media_storage.name
}

output "media_services_account_name" {
  description = "Name of the Media Services account"
  value       = azurerm_media_services_account.media_services.name
}

output "web_application_url" {
  description = "URL of the web application"
  value       = "https://${azurerm_linux_web_app.web_application.default_hostname}"
}

output "api_backend_url" {
  description = "URL of the API backend"
  value       = "https://${azurerm_linux_web_app.api_backend.default_hostname}"
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL server"
  value       = azurerm_mssql_server.application_database_server.fully_qualified_domain_name
  sensitive   = true
}

output "database_name" {
  description = "Name of the application database"
  value       = azurerm_mssql_database.application_database.name
}

output "cdn_endpoint_url" {
  description = "URL of the CDN endpoint"
  value       = "https://${azurerm_cdn_endpoint.media_endpoint.fqdn}"
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.corporate_media_vnet.name
}

output "storage_account_primary_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.media_storage.primary_blob_endpoint
}