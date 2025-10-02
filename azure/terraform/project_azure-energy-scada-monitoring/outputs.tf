output "iot_hub_hostname" {
  description = "IoT Hub hostname for SCADA device connections"
  value       = azurerm_iothub.scada_iot_hub.hostname
  sensitive   = false
}

output "iot_hub_connection_string" {
  description = "IoT Hub connection string for device management"
  value       = "HostName=${azurerm_iothub.scada_iot_hub.hostname};SharedAccessKeyName=iothubowner;SharedAccessKey=${azurerm_iothub.scada_iot_hub.shared_access_policy[0].primary_key}"
  sensitive   = true
}

output "data_explorer_cluster_uri" {
  description = "Azure Data Explorer cluster URI for time-series queries"
  value       = azurerm_kusto_cluster.time_series_database.uri
}

output "operator_dashboard_url" {
  description = "URL for the SCADA operator dashboard"
  value       = "https://${azurerm_linux_web_app.operator_dashboard.default_hostname}"
}

output "alert_processor_function_url" {
  description = "Function App URL for alert processing"
  value       = "https://${azurerm_linux_function_app.alert_processor.default_hostname}"
}

output "storage_account_name" {
  description = "Storage account name for notification and audit logs"
  value       = azurerm_storage_account.notification_storage.name
}

output "key_vault_uri" {
  description = "Key Vault URI for secrets management"
  value       = azurerm_key_vault.scada_kv.vault_uri
}

output "stream_analytics_job_name" {
  description = "Stream Analytics job name for real-time processing"
  value       = azurerm_stream_analytics_job.stream_processor.name
}

output "resource_group_name" {
  description = "Resource group containing all SCADA infrastructure"
  value       = azurerm_resource_group.smart_grid_rg.name
}

output "virtual_network_name" {
  description = "Virtual network name for SCADA operations"
  value       = azurerm_virtual_network.scada_vnet.name
}