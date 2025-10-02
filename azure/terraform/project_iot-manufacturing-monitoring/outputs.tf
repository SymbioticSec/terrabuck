output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.smart_manufacturing.name
}

output "iot_hub_name" {
  description = "Name of the IoT Hub"
  value       = azurerm_iothub.iot_hub.name
}

output "iot_hub_connection_string" {
  description = "IoT Hub connection string"
  value       = azurerm_iothub.iot_hub.shared_access_policy[0].connection_string
  sensitive   = true
}

output "stream_analytics_job_name" {
  description = "Name of the Stream Analytics job"
  value       = azurerm_stream_analytics_job.stream_processor.name
}

output "function_app_name" {
  description = "Name of the Function App for alerts"
  value       = azurerm_linux_function_app.alert_function.name
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = "https://${azurerm_linux_function_app.alert_function.name}.azurewebsites.net"
}

output "dashboard_app_name" {
  description = "Name of the dashboard web app"
  value       = azurerm_linux_web_app.dashboard_app.name
}

output "dashboard_app_url" {
  description = "URL of the dashboard web app"
  value       = "https://${azurerm_linux_web_app.dashboard_app.name}.azurewebsites.net"
}

output "kusto_cluster_name" {
  description = "Name of the Azure Data Explorer cluster"
  value       = azurerm_kusto_cluster.time_series_database.name
}

output "kusto_cluster_uri" {
  description = "URI of the Azure Data Explorer cluster"
  value       = azurerm_kusto_cluster.time_series_database.uri
}

output "storage_account_name" {
  description = "Name of the blob storage account"
  value       = azurerm_storage_account.blob_storage.name
}

output "storage_container_name" {
  description = "Name of the storage container"
  value       = azurerm_storage_container.manufacturing_data.name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.app_gateway_ip.ip_address
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.smart_manufacturing_vnet.name
}