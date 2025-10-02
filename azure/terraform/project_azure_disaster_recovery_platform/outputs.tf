output "resource_group_name" {
  description = "Name of the primary resource group"
  value       = azurerm_resource_group.dr_platform.name
}

output "secondary_resource_group_name" {
  description = "Name of the secondary resource group for DR"
  value       = azurerm_resource_group.dr_platform_secondary.name
}

output "backup_storage_account_name" {
  description = "Name of the backup storage account"
  value       = azurerm_storage_account.backup_storage.name
}

output "backup_storage_primary_endpoint" {
  description = "Primary blob endpoint for backup storage"
  value       = azurerm_storage_account.backup_storage.primary_blob_endpoint
}

output "recovery_database_connection_string" {
  description = "Connection string for the recovery database"
  value       = "Server=tcp:${azurerm_mssql_server.recovery_sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.recovery_database.name};Persist Security Info=False;User ID=${var.sql_admin_username};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive   = true
}

output "dr_orchestration_function_app_name" {
  description = "Name of the DR orchestration function app"
  value       = azurerm_linux_function_app.dr_orchestration_engine.name
}

output "dr_orchestration_function_app_url" {
  description = "URL of the DR orchestration function app"
  value       = "https://${azurerm_linux_function_app.dr_orchestration_engine.default_hostname}"
}

output "dr_web_portal_name" {
  description = "Name of the DR web portal app service"
  value       = azurerm_linux_web_app.dr_web_portal.name
}

output "dr_web_portal_url" {
  description = "URL of the DR web portal"
  value       = "https://${azurerm_linux_web_app.dr_web_portal.default_hostname}"
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.monitoring_analytics.id
}

output "communication_service_name" {
  description = "Name of the communication service for notifications"
  value       = azurerm_communication_service.notification_service.name
}

output "communication_service_connection_string" {
  description = "Connection string for the communication service"
  value       = azurerm_communication_service.notification_service.primary_connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.dr_insights.instrumentation_key
  sensitive   = true
}

output "primary_vnet_id" {
  description = "ID of the primary virtual network"
  value       = azurerm_virtual_network.dr_vnet_primary.id
}

output "secondary_vnet_id" {
  description = "ID of the secondary virtual network"
  value       = azurerm_virtual_network.dr_vnet_secondary.id
}