terraform {
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
      purge_soft_delete_on_destroy = true
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "trading_platform" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
    Owner       = "trading-team"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "trading_vnet" {
  name                = "real-time-financial-trading-platform-vnet-main"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.trading_platform.location
  resource_group_name = azurerm_resource_group.trading_platform.name

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

# Public Subnet for App Service and CDN
resource "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.trading_platform.name
  virtual_network_name = azurerm_virtual_network.trading_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private Subnet for Container Instances and Functions
resource "azurerm_subnet" "private_subnet" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.trading_platform.name
  virtual_network_name = azurerm_virtual_network.trading_vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "container-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Data Subnet for Database and Cache
resource "azurerm_subnet" "data_subnet" {
  name                 = "data-subnet"
  resource_group_name  = azurerm_resource_group.trading_platform.name
  virtual_network_name = azurerm_virtual_network.trading_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Network Security Group with vulnerable rule (AZURE-NETWORK-NO_PUBLIC_INGRESS)
resource "azurerm_network_security_group" "api_gateway_nsg" {
  name                = "api-gateway-nsg"
  location            = azurerm_resource_group.trading_platform.location
  resource_group_name = azurerm_resource_group.trading_platform.name

  security_rule {
    name                       = "allow-all-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "0.0.0.0/0"  # VULNERABLE: Allows traffic from anywhere
    destination_address_prefix = "*"
  }
}

# Storage Account for Function App and backups (AZURE-STORAGE-DEFAULT_ACTION_DENY)
resource "azurerm_storage_account" "trading_storage" {
  name                     = "tradingplatformstorage${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.trading_platform.name
  location                 = azurerm_resource_group.trading_platform.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

resource "azurerm_storage_account_network_rules" "trading_storage_rules" {
  storage_account_id = azurerm_storage_account.trading_storage.id

  default_action             = "Allow"  # VULNERABLE: Should be "Deny"
  ip_rules                   = ["127.0.0.1"]
  virtual_network_subnet_ids = [azurerm_subnet.private_subnet.id]
  bypass                     = ["Metrics"]
}

resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Key Vault for secrets (AZURE-KEYVAULT-SPECIFY_NETWORK_ACL)
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "trading_keyvault" {
  name                        = "trading-kv-${random_string.kv_suffix.result}"
  location                    = azurerm_resource_group.trading_platform.location
  resource_group_name         = azurerm_resource_group.trading_platform.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get", "Set", "List", "Delete"
    ]

    storage_permissions = [
      "Get",
    ]
  }

  # VULNERABLE: Missing network_acls block
  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

resource "random_string" "kv_suffix" {
  length  = 8
  special = false
  upper   = false
}

# SQL Server and Database (AZURE-DATABASE-SECURE_TLS_POLICY, AZURE-DATABASE-THREAT_ALERT_EMAIL_TO_OWNER)
resource "azurerm_mssql_server" "trading_sql_server" {
  name                         = "real-time-financial-trading-platform-sql-${random_string.sql_suffix.result}"
  resource_group_name          = azurerm_resource_group.trading_platform.name
  location                     = azurerm_resource_group.trading_platform.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.1"  # VULNERABLE: Should be "1.2"

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

resource "azurerm_mssql_database" "trading_database" {
  name           = "trading-database"
  server_id      = azurerm_mssql_server.trading_sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 100
  sku_name       = "S2"
  zone_redundant = false

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

resource "azurerm_mssql_server_security_alert_policy" "trading_sql_alert" {
  resource_group_name        = azurerm_resource_group.trading_platform.name
  server_name                = azurerm_mssql_server.trading_sql_server.name
  state                      = "Enabled"
  storage_endpoint           = azurerm_storage_account.trading_storage.primary_blob_endpoint
  storage_account_access_key = azurerm_storage_account.trading_storage.primary_access_key
  disabled_alerts            = []

  email_account_admins = false  # VULNERABLE: Should be true
}

resource "random_string" "sql_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Redis Cache for market data
resource "azurerm_redis_cache" "market_data_cache" {
  name                = "real-time-financial-trading-platform-redis-${random_string.redis_suffix.result}"
  location            = azurerm_resource_group.trading_platform.location
  resource_group_name = azurerm_resource_group.trading_platform.name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

resource "random_string" "redis_suffix" {
  length  = 8
  special = false
  upper   = false
}

# App Service Plan
resource "azurerm_service_plan" "trading_app_plan" {
  name                = "real-time-financial-trading-platform-plan"
  resource_group_name = azurerm_resource_group.trading_platform.name
  location            = azurerm_resource_group.trading_platform.location
  os_type             = "Linux"
  sku_name            = "P1v2"

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

# App Service for Trading Web Frontend (AZURE-APPSERVICE-USE_SECURE_TLS_POLICY)
resource "azurerm_linux_web_app" "trading_web_frontend" {
  name                = "real-time-financial-trading-platform-webapp-${random_string.webapp_suffix.result}"
  resource_group_name = azurerm_resource_group.trading_platform.name
  location            = azurerm_service_plan.trading_app_plan.location
  service_plan_id     = azurerm_service_plan.trading_app_plan.id

  site_config {
    minimum_tls_version = "1.0"  # VULNERABLE: Should be "1.2"
    
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "API_GATEWAY_URL" = "https://${azurerm_api_management.trading_api_gateway.gateway_url}"
    "CDN_ENDPOINT"    = azurerm_cdn_endpoint.trading_cdn.host_name
  }

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

resource "random_string" "webapp_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Function App for Portfolio Service (AZURE-APPSERVICE-ENFORCE_HTTPS)
resource "azurerm_linux_function_app" "portfolio_service" {
  name                = "real-time-financial-trading-platform-func-${random_string.func_suffix.result}"
  resource_group_name = azurerm_resource_group.trading_platform.name
  location            = azurerm_resource_group.trading_platform.location

  storage_account_name       = azurerm_storage_account.trading_storage.name
  storage_account_access_key = azurerm_storage_account.trading_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.trading_app_plan.id

  # VULNERABLE: Missing https_only = true

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }

  app_settings = {
    "SQL_CONNECTION_STRING" = "Server=tcp:${azurerm_mssql_server.trading_sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.trading_database.name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${var.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    "REDIS_CONNECTION_STRING" = azurerm_redis_cache.market_data_cache.primary_connection_string
  }

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

resource "random_string" "func_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Container Instance for Trading Engine
resource "azurerm_container_group" "trading_engine" {
  name                = "real-time-financial-trading-platform-container-engine"
  location            = azurerm_resource_group.trading_platform.location
  resource_group_name = azurerm_resource_group.trading_platform.name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.private_subnet.id]
  os_type             = "Linux"

  container {
    name   = "trading-engine"
    image  = "nginx:latest"
    cpu    = "1"
    memory = "2"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      "SQL_SERVER" = azurerm_mssql_server.trading_sql_server.fully_qualified_domain_name
      "REDIS_HOST" = azurerm_redis_cache.market_data_cache.hostname
    }
  }

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

# API Management for API Gateway
resource "azurerm_api_management" "trading_api_gateway" {
  name                = "real-time-financial-trading-platform-apim-${random_string.apim_suffix.result}"
  location            = azurerm_resource_group.trading_platform.location
  resource_group_name = azurerm_resource_group.trading_platform.name
  publisher_name      = "Trading Platform"
  publisher_email     = var.publisher_email

  sku_name = "Developer_1"

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

resource "random_string" "apim_suffix" {
  length  = 8
  special = false
  upper   = false
}

# CDN Profile and Endpoint
resource "azurerm_cdn_profile" "trading_cdn_profile" {
  name                = "real-time-financial-trading-platform-cdn-profile"
  location            = azurerm_resource_group.trading_platform.location
  resource_group_name = azurerm_resource_group.trading_platform.name
  sku                 = "Standard_Microsoft"

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

resource "azurerm_cdn_endpoint" "trading_cdn" {
  name                = "real-time-financial-trading-platform-cdn-${random_string.cdn_suffix.result}"
  profile_name        = azurerm_cdn_profile.trading_cdn_profile.name
  location            = azurerm_resource_group.trading_platform.location
  resource_group_name = azurerm_resource_group.trading_platform.name

  origin {
    name      = "webapp-origin"
    host_name = azurerm_linux_web_app.trading_web_frontend.default_hostname
  }

  tags = {
    Environment = var.environment
    Project     = "fintech-trading-platform"
  }
}

resource "random_string" "cdn_suffix" {
  length  = 8
  special = false
  upper   = false
}