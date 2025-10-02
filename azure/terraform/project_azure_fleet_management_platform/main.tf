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
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "fleet_management" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "fleet_vnet" {
  name                = "vnet-${var.project_name}-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.fleet_management.location
  resource_group_name = azurerm_resource_group.fleet_management.name
  tags                = var.tags
}

# Public Subnet for Application Gateway
resource "azurerm_subnet" "public_subnet" {
  name                 = "snet-public-${var.environment}"
  resource_group_name  = azurerm_resource_group.fleet_management.name
  virtual_network_name = azurerm_virtual_network.fleet_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private Subnet for App Service and Functions
resource "azurerm_subnet" "private_subnet" {
  name                 = "snet-private-${var.environment}"
  resource_group_name  = azurerm_resource_group.fleet_management.name
  virtual_network_name = azurerm_virtual_network.fleet_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  
  delegation {
    name = "Microsoft.Web/serverFarms"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

# Data Subnet for SQL Database
resource "azurerm_subnet" "data_subnet" {
  name                 = "snet-data-${var.environment}"
  resource_group_name  = azurerm_resource_group.fleet_management.name
  virtual_network_name = azurerm_virtual_network.fleet_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}

# Network Security Group for Private Subnet
resource "azurerm_network_security_group" "private_nsg" {
  name                = "nsg-private-${var.environment}"
  location            = azurerm_resource_group.fleet_management.location
  resource_group_name = azurerm_resource_group.fleet_management.name
  tags                = var.tags
}

# Vulnerable NSG Rule - Allows all outbound traffic
resource "azurerm_network_security_rule" "allow_all_outbound" {
  name                        = "AllowAllOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "0.0.0.0/0"
  resource_group_name        = azurerm_resource_group.fleet_management.name
  network_security_group_name = azurerm_network_security_group.private_nsg.name
}

# Associate NSG with Private Subnet
resource "azurerm_subnet_network_security_group_association" "private_nsg_association" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.private_nsg.id
}

# Storage Account for Map Tiles
resource "azurerm_storage_account" "map_tile_storage" {
  name                     = "st${replace(var.project_name, "-", "")}${var.environment}"
  resource_group_name      = azurerm_resource_group.fleet_management.name
  location                 = azurerm_resource_group.fleet_management.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags

  # Missing queue logging configuration - vulnerability
  queue_properties {
  }
}

# Vulnerable Storage Container - Public blob access
resource "azurerm_storage_container" "map_tiles" {
  name                  = "map-tiles"
  storage_account_name  = azurerm_storage_account.map_tile_storage.name
  container_access_type = "blob"
}

# Event Hubs Namespace for Vehicle Telemetry
resource "azurerm_eventhub_namespace" "vehicle_telemetry" {
  name                = "evhns-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.fleet_management.location
  resource_group_name = azurerm_resource_group.fleet_management.name
  sku                 = "Standard"
  capacity            = 1
  tags                = var.tags
}

# Event Hub for Telemetry Data
resource "azurerm_eventhub" "telemetry_ingestion" {
  name                = "evh-telemetry-${var.environment}"
  namespace_name      = azurerm_eventhub_namespace.vehicle_telemetry.name
  resource_group_name = azurerm_resource_group.fleet_management.name
  partition_count     = 2
  message_retention   = 1
}

# SQL Server for Fleet Database
resource "azurerm_mssql_server" "fleet_database_server" {
  name                         = "sql-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.fleet_management.name
  location                     = azurerm_resource_group.fleet_management.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  tags                         = var.tags
}

# Vulnerable SQL Firewall Rule - Open to Internet
resource "azurerm_mssql_firewall_rule" "allow_all_ips" {
  name             = "AllowAllIPs"
  server_id        = azurerm_mssql_server.fleet_database_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

# SQL Database
resource "azurerm_mssql_database" "fleet_database" {
  name      = "sqldb-fleet-${var.environment}"
  server_id = azurerm_mssql_server.fleet_database_server.id
  sku_name  = "S0"
  tags      = var.tags
}

# App Service Plan
resource "azurerm_service_plan" "fleet_app_plan" {
  name                = "asp-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.fleet_management.name
  location            = azurerm_resource_group.fleet_management.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = var.tags
}

# Vulnerable App Service - No authentication and no HTTP/2
resource "azurerm_linux_web_app" "fleet_management_webapp" {
  name                = "app-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.fleet_management.name
  location            = azurerm_service_plan.fleet_app_plan.location
  service_plan_id     = azurerm_service_plan.fleet_app_plan.id
  tags                = var.tags

  site_config {
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "DATABASE_CONNECTION_STRING" = "Server=${azurerm_mssql_server.fleet_database_server.fully_qualified_domain_name};Database=${azurerm_mssql_database.fleet_database.name};User Id=${var.sql_admin_username};Password=${var.sql_admin_password};"
    "STORAGE_ACCOUNT_NAME"       = azurerm_storage_account.map_tile_storage.name
    "EVENTHUB_CONNECTION_STRING" = azurerm_eventhub_namespace.vehicle_telemetry.default_primary_connection_string
  }
}

# Storage Account for Function App
resource "azurerm_storage_account" "function_storage" {
  name                     = "stfunc${replace(var.project_name, "-", "")}${var.environment}"
  resource_group_name      = azurerm_resource_group.fleet_management.name
  location                 = azurerm_resource_group.fleet_management.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Function App for Telemetry Processing
resource "azurerm_linux_function_app" "telemetry_processor" {
  name                = "func-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.fleet_management.name
  location            = azurerm_resource_group.fleet_management.location
  service_plan_id     = azurerm_service_plan.fleet_app_plan.id
  
  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  tags                       = var.tags

  site_config {
    application_stack {
      node_version = "18"
    }
  }

  app_settings = {
    "DATABASE_CONNECTION_STRING" = "Server=${azurerm_mssql_server.fleet_database_server.fully_qualified_domain_name};Database=${azurerm_mssql_database.fleet_database.name};User Id=${var.sql_admin_username};Password=${var.sql_admin_password};"
    "EVENTHUB_CONNECTION_STRING" = azurerm_eventhub_namespace.vehicle_telemetry.default_primary_connection_string
  }
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "app_gateway_pip" {
  name                = "pip-appgw-${var.environment}"
  resource_group_name = azurerm_resource_group.fleet_management.name
  location            = azurerm_resource_group.fleet_management.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Application Gateway
resource "azurerm_application_gateway" "fleet_app_gateway" {
  name                = "appgw-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.fleet_management.name
  location            = azurerm_resource_group.fleet_management.location
  tags                = var.tags

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.public_subnet.id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.app_gateway_pip.id
  }

  backend_address_pool {
    name  = "backend-pool"
    fqdns = [azurerm_linux_web_app.fleet_management_webapp.default_hostname]
  }

  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "backend-http-settings"
    priority                   = 100
  }
}

# CDN Profile for Map Tiles
resource "azurerm_cdn_profile" "map_cdn" {
  name                = "cdn-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.fleet_management.location
  resource_group_name = azurerm_resource_group.fleet_management.name
  sku                 = "Standard_Microsoft"
  tags                = var.tags
}

# CDN Endpoint
resource "azurerm_cdn_endpoint" "map_tiles_endpoint" {
  name                = "cdn-maptiles-${var.environment}"
  profile_name        = azurerm_cdn_profile.map_cdn.name
  location            = azurerm_resource_group.fleet_management.location
  resource_group_name = azurerm_resource_group.fleet_management.name

  origin {
    name      = "map-tiles-origin"
    host_name = azurerm_storage_account.map_tile_storage.primary_blob_host
  }
}