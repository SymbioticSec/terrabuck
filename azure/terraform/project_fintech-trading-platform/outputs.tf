output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.trading_platform.name
}

output "trading_web_frontend_url" {
  description = "URL of the trading web frontend"
  value       = "https://${azurerm_linux_web_app.trading_web_frontend.default_hostname}"
}

output "api_gateway_url" {
  description = "URL of the API Management gateway"
  value       = "https://${azurerm_api_management.trading_api_gateway.gateway_url}"
}

output "portfolio_service_url" {
  description = "URL of the portfolio service function app"
  value       = "https://${azurerm_linux_function_app.portfolio_service.default_hostname}"
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL server"
  value       = azurerm_mssql_server.trading_sql_server.fully_qualified_domain_name
  sensitive   = true
}

output "redis_hostname" {
  description = "Hostname of the Redis cache"
  value       = azurerm_redis_cache.market_data_cache.hostname
  sensitive   = true
}

output "cdn_endpoint_url" {
  description = "URL of the CDN endpoint"
  value       = "https://${azurerm_cdn_endpoint.trading_cdn.host_name}"
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.trading_keyvault.vault_uri
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.trading_storage.name
}

output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.trading_vnet.id
}