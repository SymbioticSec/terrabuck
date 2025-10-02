output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.telehealth_rg.name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway_pip.ip_address
}

output "web_app_url" {
  description = "URL of the consultation web application"
  value       = "https://${azurerm_linux_web_app.consultation_web_app.default_hostname}"
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL server"
  value       = azurerm_mssql_server.consultation_sql_server.fully_qualified_domain_name
  sensitive   = true
}

output "medical_records_storage_account_name" {
  description = "Name of the medical records storage account"
  value       = azurerm_storage_account.medical_records_storage.name
}

output "media_services_account_name" {
  description = "Name of the Media Services account for video streaming"
  value       = azurerm_media_services_account.video_streaming_service.name
}

output "function_app_name" {
  description = "Name of the notification service function app"
  value       = azurerm_linux_function_app.notification_service.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.telehealth_kv.vault_uri
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.telehealth_vnet.id
}

output "database_connection_string" {
  description = "Connection string for the consultation database"
  value       = "Server=${azurerm_mssql_server.consultation_sql_server.fully_qualified_domain_name};Database=${azurerm_mssql_database.consultation_database.name};User Id=${var.sql_admin_username};Password=${var.sql_admin_password};"
  sensitive   = true
}