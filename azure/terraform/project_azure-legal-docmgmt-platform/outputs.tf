output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.legal_platform.name
}

output "web_app_url" {
  description = "URL of the legal document management web application"
  value       = "https://${azurerm_linux_web_app.legal_web_app.default_hostname}"
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.legal_app_gateway_pip.ip_address
}

output "storage_account_name" {
  description = "Name of the storage account for legal documents"
  value       = azurerm_storage_account.legal_documents.name
}

output "key_vault_name" {
  description = "Name of the Key Vault for secrets management"
  value       = azurerm_key_vault.legal_keyvault.name
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.legal_sql_server.fully_qualified_domain_name
  sensitive   = true
}

output "search_service_name" {
  description = "Name of the Azure Cognitive Search service"
  value       = azurerm_search_service.legal_search.name
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.legal_vnet.name
}