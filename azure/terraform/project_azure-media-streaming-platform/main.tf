terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "corporate_media_streaming" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
    Owner       = "IT-Department"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "corporate_media_vnet" {
  name                = "corporate-media-streaming-platform-vnet-main"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.corporate_media_streaming.location
  resource_group_name = azurerm_resource_group.corporate_media_streaming.name

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
  }
}

# Web Tier Subnet
resource "azurerm_subnet" "web_tier_subnet" {
  name                 = "corporate-media-streaming-platform-subnet-web"
  resource_group_name  = azurerm_resource_group.corporate_media_streaming.name
  virtual_network_name = azurerm_virtual_network.corporate_media_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Web", "Microsoft.Storage"]
}

# Data Tier Subnet
resource "azurerm_subnet" "data_tier_subnet" {
  name                 = "corporate-media-streaming-platform-subnet-data"
  resource_group_name  = azurerm_resource_group.corporate_media_streaming.name
  virtual_network_name = azurerm_virtual_network.corporate_media_vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  service_endpoints = ["Microsoft.Sql"]
}

# Integration Subnet
resource "azurerm_subnet" "integration_subnet" {
  name                 = "corporate-media-streaming-platform-subnet-integration"
  resource_group_name  = azurerm_resource_group.corporate_media_streaming.name
  virtual_network_name = azurerm_virtual_network.corporate_media_vnet.name
  address_prefixes     = ["10.0.3.0/24"]

  service_endpoints = ["Microsoft.Media", "Microsoft.Storage"]
}

# Network Security Group with vulnerable RDP rule
resource "azurerm_network_security_group" "corporate_media_nsg" {
  name                = "corporate-media-streaming-platform-nsg-main"
  location            = azurerm_resource_group.corporate_media_streaming.location
  resource_group_name = azurerm_resource_group.corporate_media_streaming.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # VULNERABILITY: RDP from internet
  security_rule {
    name                       = "AllowRDP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
  }
}

# Media Storage Account with vulnerabilities
resource "azurerm_storage_account" "media_storage" {
  name                     = "corpmediastorage${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.corporate_media_streaming.name
  location                 = azurerm_resource_group.corporate_media_streaming.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  # VULNERABILITY: HTTPS not enforced
  enable_https_traffic_only = false
  
  # VULNERABILITY: Weak TLS policy
  min_tls_version = "TLS1_0"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
    Component   = "media-storage"
  }
}

resource "azurerm_storage_container" "raw_videos" {
  name                  = "raw-videos"
  storage_account_name  = azurerm_storage_account.media_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "transcoded_videos" {
  name                  = "transcoded-videos"
  storage_account_name  = azurerm_storage_account.media_storage.name
  container_access_type = "private"
}

# Random string for unique naming
resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# SQL Server
resource "azurerm_mssql_server" "application_database_server" {
  name                         = "corporate-media-streaming-platform-sqlserver-${random_string.storage_suffix.result}"
  resource_group_name          = azurerm_resource_group.corporate_media_streaming.name
  location                     = azurerm_resource_group.corporate_media_streaming.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  
  # VULNERABILITY: Public network access enabled
  public_network_access_enabled = true

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
    Component   = "application-database"
  }
}

# Application Database
resource "azurerm_mssql_database" "application_database" {
  name           = "corporate-media-streaming-platform-database-app"
  server_id      = azurerm_mssql_server.application_database_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 20
  sku_name       = "S0"
  zone_redundant = false

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
    Component   = "application-database"
  }
}

# Media Services Account
resource "azurerm_media_services_account" "media_services" {
  name                = "corpmediastreamingms${random_string.storage_suffix.result}"
  location            = azurerm_resource_group.corporate_media_streaming.location
  resource_group_name = azurerm_resource_group.corporate_media_streaming.name

  storage_account {
    id         = azurerm_storage_account.media_storage.id
    is_primary = true
  }

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
    Component   = "media-services"
  }
}

# App Service Plan
resource "azurerm_service_plan" "corporate_media_plan" {
  name                = "corporate-media-streaming-platform-plan-main"
  resource_group_name = azurerm_resource_group.corporate_media_streaming.name
  location            = azurerm_resource_group.corporate_media_streaming.location
  os_type             = "Linux"
  sku_name            = "P1v2"

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
  }
}

# Web Application App Service with vulnerabilities
resource "azurerm_linux_web_app" "web_application" {
  name                = "corporate-media-streaming-platform-webapp-${random_string.storage_suffix.result}"
  resource_group_name = azurerm_resource_group.corporate_media_streaming.name
  location            = azurerm_service_plan.corporate_media_plan.location
  service_plan_id     = azurerm_service_plan.corporate_media_plan.id

  site_config {
    always_on = true
    # VULNERABILITY: HTTP2 not enabled
    http2_enabled = false
    
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "MEDIA_SERVICES_ACCOUNT_NAME"         = azurerm_media_services_account.media_services.name
    "STORAGE_ACCOUNT_NAME"                = azurerm_storage_account.media_storage.name
  }

  # VULNERABILITY: No managed identity configured
  # identity block is omitted

  # VULNERABILITY: No authentication enabled
  # auth_settings block is omitted

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
    Component   = "web-application"
  }
}

# API Backend App Service with vulnerabilities
resource "azurerm_linux_web_app" "api_backend" {
  name                = "corporate-media-streaming-platform-api-${random_string.storage_suffix.result}"
  resource_group_name = azurerm_resource_group.corporate_media_streaming.name
  location            = azurerm_service_plan.corporate_media_plan.location
  service_plan_id     = azurerm_service_plan.corporate_media_plan.id

  site_config {
    always_on = true
    
    application_stack {
      node_version = "18-lts"
    }

    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DATABASE_CONNECTION_STRING"          = "Server=${azurerm_mssql_server.application_database_server.fully_qualified_domain_name};Database=${azurerm_mssql_database.application_database.name};User Id=${var.sql_admin_username};Password=${var.sql_admin_password};"
    "MEDIA_SERVICES_ACCOUNT_NAME"         = azurerm_media_services_account.media_services.name
  }

  # VULNERABILITY: No managed identity configured
  # identity block is omitted

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
    Component   = "api-backend"
  }
}

# CDN Profile
resource "azurerm_cdn_profile" "cdn_distribution" {
  name                = "corporate-media-streaming-platform-cdn-main"
  location            = azurerm_resource_group.corporate_media_streaming.location
  resource_group_name = azurerm_resource_group.corporate_media_streaming.name
  sku                 = "Standard_Microsoft"

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
    Component   = "cdn-distribution"
  }
}

# CDN Endpoint
resource "azurerm_cdn_endpoint" "media_endpoint" {
  name                = "corporate-media-streaming-platform-endpoint-${random_string.storage_suffix.result}"
  profile_name        = azurerm_cdn_profile.cdn_distribution.name
  location            = azurerm_resource_group.corporate_media_streaming.location
  resource_group_name = azurerm_resource_group.corporate_media_streaming.name

  origin {
    name      = "media-services-origin"
    host_name = "${azurerm_media_services_account.media_services.name}.streaming.media.azure.net"
  }

  tags = {
    Environment = var.environment
    Project     = "corporate-media-streaming-platform"
    Component   = "cdn-distribution"
  }
}