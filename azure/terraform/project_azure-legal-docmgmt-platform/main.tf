terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "legal_platform" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "Legal Document Management Platform"
    Owner       = "Legal IT Team"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "legal_vnet" {
  name                = "legal-document-management-platform-vnet-main"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.legal_platform.location
  resource_group_name = azurerm_resource_group.legal_platform.name

  tags = {
    Environment = var.environment
    Component   = "Network"
  }
}

# Public Subnet for Application Gateway
resource "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.legal_platform.name
  virtual_network_name = azurerm_virtual_network.legal_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private Subnet for App Service
resource "azurerm_subnet" "private_subnet" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.legal_platform.name
  virtual_network_name = azurerm_virtual_network.legal_vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "app-service-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Data Subnet for Database
resource "azurerm_subnet" "data_subnet" {
  name                 = "data-subnet"
  resource_group_name  = azurerm_resource_group.legal_platform.name
  virtual_network_name = azurerm_virtual_network.legal_vnet.name
  address_prefixes     = ["10.0.3.0/24"]

  service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
}

# Network Security Group for Public Subnet - VULNERABLE: SSH from internet
resource "azurerm_network_security_group" "public_nsg" {
  name                = "legal-document-management-platform-nsg-public"
  location            = azurerm_resource_group.legal_platform.location
  resource_group_name = azurerm_resource_group.legal_platform.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSHFromInternet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Component   = "Security"
  }
}

# Network Security Group for Private Subnet
resource "azurerm_network_security_group" "private_nsg" {
  name                = "legal-document-management-platform-nsg-private"
  location            = azurerm_resource_group.legal_platform.location
  resource_group_name = azurerm_resource_group.legal_platform.name

  security_rule {
    name                       = "AllowAppGateway"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Component   = "Security"
  }
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "public_nsg_association" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "private_nsg_association" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

# Key Vault - VULNERABLE: No network ACLs
resource "azurerm_key_vault" "legal_keyvault" {
  name                        = "legal-document-management-platform-kv-${random_string.suffix.result}"
  location                    = azurerm_resource_group.legal_platform.location
  resource_group_name         = azurerm_resource_group.legal_platform.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Recover", "Purge"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Purge"
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update", "ManageContacts", "ManageIssuers"
    ]
  }

  tags = {
    Environment = var.environment
    Component   = "Security"
  }
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Key Vault Secret - VULNERABLE: No expiration date
resource "azurerm_key_vault_secret" "database_connection_string" {
  name         = "database-connection-string"
  value        = "Server=tcp:${azurerm_mssql_server.legal_sql_server.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.legal_metadata_db.name};User ID=${var.sql_admin_username};Password=${var.sql_admin_password};Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.legal_keyvault.id

  depends_on = [azurerm_mssql_database.legal_metadata_db]

  tags = {
    Environment = var.environment
    Component   = "Security"
  }
}

# Storage Account - VULNERABLE: Weak TLS version
resource "azurerm_storage_account" "legal_documents" {
  name                     = "legaldocmgmt${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.legal_platform.name
  location                 = azurerm_resource_group.legal_platform.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_0"

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 365
    }
  }

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.data_subnet.id, azurerm_subnet.private_subnet.id]
  }

  tags = {
    Environment = var.environment
    Component   = "Storage"
  }
}

# Storage Container for Documents
resource "azurerm_storage_container" "legal_documents_container" {
  name                  = "legal-documents"
  storage_account_name  = azurerm_storage_account.legal_documents.name
  container_access_type = "private"
}

# SQL Server - VULNERABLE: SSL enforcement disabled
resource "azurerm_mssql_server" "legal_sql_server" {
  name                         = "legal-document-management-platform-sql-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.legal_platform.name
  location                     = azurerm_resource_group.legal_platform.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.0"

  tags = {
    Environment = var.environment
    Component   = "Database"
  }
}

# SQL Database
resource "azurerm_mssql_database" "legal_metadata_db" {
  name           = "legal-document-management-platform-database-metadata"
  server_id      = azurerm_mssql_server.legal_sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 100
  sku_name       = "S2"
  zone_redundant = false

  tags = {
    Environment = var.environment
    Component   = "Database"
  }
}

# SQL Firewall Rule for VNet
resource "azurerm_mssql_virtual_network_rule" "legal_sql_vnet_rule" {
  name      = "legal-sql-vnet-rule"
  server_id = azurerm_mssql_server.legal_sql_server.id
  subnet_id = azurerm_subnet.data_subnet.id
}

# App Service Plan
resource "azurerm_service_plan" "legal_app_plan" {
  name                = "legal-document-management-platform-plan-main"
  resource_group_name = azurerm_resource_group.legal_platform.name
  location            = azurerm_resource_group.legal_platform.location
  os_type             = "Linux"
  sku_name            = "P1v2"

  tags = {
    Environment = var.environment
    Component   = "Compute"
  }
}

# App Service - VULNERABLE: HTTP/2 not enabled
resource "azurerm_linux_web_app" "legal_web_app" {
  name                = "legal-document-management-platform-app-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.legal_platform.name
  location            = azurerm_service_plan.legal_app_plan.location
  service_plan_id     = azurerm_service_plan.legal_app_plan.id

  site_config {
    always_on = true
    application_stack {
      dotnet_version = "6.0"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "KeyVaultName"                        = azurerm_key_vault.legal_keyvault.name
    "StorageAccountName"                  = azurerm_storage_account.legal_documents.name
    "SearchServiceName"                   = azurerm_search_service.legal_search.name
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
    Component   = "Application"
  }
}

# VNet Integration for App Service
resource "azurerm_app_service_virtual_network_swift_connection" "legal_app_vnet_integration" {
  app_service_id = azurerm_linux_web_app.legal_web_app.id
  subnet_id      = azurerm_subnet.private_subnet.id
}

# Cognitive Search Service
resource "azurerm_search_service" "legal_search" {
  name                = "legal-document-management-platform-search-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.legal_platform.name
  location            = azurerm_resource_group.legal_platform.location
  sku                 = "standard"
  replica_count       = 1
  partition_count     = 1

  tags = {
    Environment = var.environment
    Component   = "Search"
  }
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "legal_app_gateway_pip" {
  name                = "legal-document-management-platform-pip-gateway"
  resource_group_name = azurerm_resource_group.legal_platform.name
  location            = azurerm_resource_group.legal_platform.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Component   = "Network"
  }
}

# Application Gateway
resource "azurerm_application_gateway" "legal_app_gateway" {
  name                = "legal-document-management-platform-gateway-main"
  resource_group_name = azurerm_resource_group.legal_platform.name
  location            = azurerm_resource_group.legal_platform.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "legal-gateway-ip-configuration"
    subnet_id = azurerm_subnet.public_subnet.id
  }

  frontend_port {
    name = "legal-frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "legal-frontend-ip"
    public_ip_address_id = azurerm_public_ip.legal_app_gateway_pip.id
  }

  backend_address_pool {
    name  = "legal-backend-pool"
    fqdns = [azurerm_linux_web_app.legal_web_app.default_hostname]
  }

  backend_http_settings {
    name                  = "legal-backend-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "legal-http-listener"
    frontend_ip_configuration_name = "legal-frontend-ip"
    frontend_port_name             = "legal-frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "legal-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "legal-http-listener"
    backend_address_pool_name  = "legal-backend-pool"
    backend_http_settings_name = "legal-backend-http-settings"
    priority                   = 100
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  tags = {
    Environment = var.environment
    Component   = "Network"
  }
}

# Monitor Log Profile - VULNERABLE: Short retention period
resource "azurerm_monitor_log_profile" "legal_log_profile" {
  name = "legal-document-management-platform-logs"

  categories = [
    "Action",
    "Delete",
    "Write",
  ]

  locations = [
    "westus",
    "global",
  ]

  retention_policy {
    enabled = true
    days    = 7
  }

  storage_account_id = azurerm_storage_account.legal_documents.id
}