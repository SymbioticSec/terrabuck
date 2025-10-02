output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.healthcare_portal.name
}

output "web_app_url" {
  description = "URL of the patient portal web application"
  value       = "https://${azurerm_linux_web_app.web_frontend.default_hostname}"
}

output "api_management_gateway_url" {
  description = "URL of the API Management gateway"
  value       = azurerm_api_management.healthcare_apim.gateway_url
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.patient_db.fully_qualified_domain_name
  sensitive   = true
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.healthcare_kv.vault_uri
}

output "storage_account_name" {
  description = "Name of the storage account for medical documents"
  value       = azurerm_storage_account.file_storage.name
}

output "container_group_ip" {
  description = "Private IP address of the backend container group"
  value       = azurerm_container_group.backend_services.ip_address
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.healthcare_vnet.id
}