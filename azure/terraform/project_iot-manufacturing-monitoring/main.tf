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
  }
}

# Resource Group
resource "azurerm_resource_group" "smart_manufacturing" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
    Owner       = var.owner
  }
}

# Virtual Network
resource "azurerm_virtual_network" "smart_manufacturing_vnet" {
  name                = "smart-manufacturing-iot-monitoring-platform-vnet-main"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.smart_manufacturing.location
  resource_group_name = azurerm_resource_group.smart_manufacturing.name

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
  }
}

# Public Subnet
resource "azurerm_subnet" "public_subnet" {
  name                 = "smart-manufacturing-iot-monitoring-platform-subnet-public"
  resource_group_name  = azurerm_resource_group.smart_manufacturing.name
  virtual_network_name = azurerm_virtual_network.smart_manufacturing_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private Subnet
resource "azurerm_subnet" "private_subnet" {
  name                 = "smart-manufacturing-iot-monitoring-platform-subnet-private"
  resource_group_name  = azurerm_resource_group.smart_manufacturing.name
  virtual_network_name = azurerm_virtual_network.smart_manufacturing_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Data Subnet
resource "azurerm_subnet" "data_subnet" {
  name                 = "smart-manufacturing-iot-monitoring-platform-subnet-data"
  resource_group_name  = azurerm_resource_group.smart_manufacturing.name
  virtual_network_name = azurerm_virtual_network.smart_manufacturing_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Network Security Group for Public Subnet
resource "azurerm_network_security_group" "public_nsg" {
  name                = "smart-manufacturing-iot-monitoring-platform-nsg-public"
  location            = azurerm_resource_group.smart_manufacturing.location
  resource_group_name = azurerm_resource_group.smart_manufacturing.name

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

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
  }
}

# Network Security Group for Private Subnet - VULNERABLE: Allows unrestricted outbound traffic
resource "azurerm_network_security_group" "private_nsg" {
  name                = "smart-manufacturing-iot-monitoring-platform-nsg-private"
  location            = azurerm_resource_group.smart_manufacturing.location
  resource_group_name = azurerm_resource_group.smart_manufacturing.name

  security_rule {
    name                       = "AllowOutboundInternet"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "0.0.0.0/0"
  }

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
  }
}

# Storage Account for Blob Storage - VULNERABLE: Network rules allow all access
resource "azurerm_storage_account" "blob_storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.smart_manufacturing.name
  location                 = azurerm_resource_group.smart_manufacturing.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
    Component   = "blob-storage"
  }
}

# Storage Account Network Rules - VULNERABLE: Default action allows all access
resource "azurerm_storage_account_network_rules" "blob_storage_network_rules" {
  storage_account_id = azurerm_storage_account.blob_storage.id

  default_action             = "Allow"
  ip_rules                   = ["127.0.0.1"]
  virtual_network_subnet_ids = [azurerm_subnet.private_subnet.id]
  bypass                     = ["Metrics"]
}

# Storage Container - VULNERABLE: Public blob access enabled
resource "azurerm_storage_container" "manufacturing_data" {
  name                  = "manufacturing-data-archives"
  storage_account_name  = azurerm_storage_account.blob_storage.name
  container_access_type = "blob"
}

# IoT Hub
resource "azurerm_iothub" "iot_hub" {
  name                = "smart-manufacturing-iot-monitoring-platform-iothub-main"
  resource_group_name = azurerm_resource_group.smart_manufacturing.name
  location            = azurerm_resource_group.smart_manufacturing.location

  sku {
    name     = "S1"
    capacity = "1"
  }

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
    Component   = "iot-hub"
  }
}

# Stream Analytics Job
resource "azurerm_stream_analytics_job" "stream_processor" {
  name                                     = "smart-manufacturing-iot-monitoring-platform-stream-analytics-processor"
  resource_group_name                      = azurerm_resource_group.smart_manufacturing.name
  location                                 = azurerm_resource_group.smart_manufacturing.location
  compatibility_level                      = "1.2"
  data_locale                             = "en-GB"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy              = "Adjust"
  output_error_policy                     = "Drop"
  streaming_units                         = 3

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
    Component   = "stream-processor"
  }
}

# Monitor Log Profile - VULNERABLE: Short retention period
resource "azurerm_monitor_log_profile" "manufacturing_logs" {
  name = "smart-manufacturing-iot-monitoring-platform-monitor-logs"

  categories = [
    "Action",
    "Delete",
    "Write",
  ]

  locations = [
    "westus",
    "global",
  ]

  storage_account_id = azurerm_storage_account.blob_storage.id

  retention_policy {
    enabled = true
    days    = 7
  }
}

# App Service Plan
resource "azurerm_service_plan" "dashboard_plan" {
  name                = "smart-manufacturing-iot-monitoring-platform-app-service-plan"
  resource_group_name = azurerm_resource_group.smart_manufacturing.name
  location            = azurerm_resource_group.smart_manufacturing.location
  os_type             = "Linux"
  sku_name            = "P1v2"

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
  }
}

# App Service for Dashboard - VULNERABLE: No authentication configured
resource "azurerm_linux_web_app" "dashboard_app" {
  name                = "smart-manufacturing-iot-monitoring-platform-app-service-dashboard"
  resource_group_name = azurerm_resource_group.smart_manufacturing.name
  location            = azurerm_service_plan.dashboard_plan.location
  service_plan_id     = azurerm_service_plan.dashboard_plan.id

  site_config {
    always_on = true
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
    Component   = "dashboard-app"
  }
}

# Storage Account for Function App
resource "azurerm_storage_account" "function_storage" {
  name                     = var.function_storage_account_name
  resource_group_name      = azurerm_resource_group.smart_manufacturing.name
  location                 = azurerm_resource_group.smart_manufacturing.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
  }
}

# Function App - VULNERABLE: HTTPS not enforced
resource "azurerm_linux_function_app" "alert_function" {
  name                = "smart-manufacturing-iot-monitoring-platform-function-app-alerts"
  resource_group_name = azurerm_resource_group.smart_manufacturing.name
  location            = azurerm_resource_group.smart_manufacturing.location
  service_plan_id     = azurerm_service_plan.dashboard_plan.id

  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key

  site_config {
    application_stack {
      node_version = "18"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "node"
  }

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
    Component   = "alert-function"
  }
}

# Data Explorer Cluster
resource "azurerm_kusto_cluster" "time_series_database" {
  name                = var.kusto_cluster_name
  location            = azurerm_resource_group.smart_manufacturing.location
  resource_group_name = azurerm_resource_group.smart_manufacturing.name

  sku {
    name     = "Standard_D13_v2"
    capacity = 2
  }

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
    Component   = "time-series-database"
  }
}

# Data Explorer Database
resource "azurerm_kusto_database" "manufacturing_timeseries" {
  name                = "manufacturing-timeseries-db"
  resource_group_name = azurerm_resource_group.smart_manufacturing.name
  location            = azurerm_resource_group.smart_manufacturing.location
  cluster_name        = azurerm_kusto_cluster.time_series_database.name

  hot_cache_period   = "P7D"
  soft_delete_period = "P31D"
}

# Application Gateway
resource "azurerm_public_ip" "app_gateway_ip" {
  name                = "smart-manufacturing-iot-monitoring-platform-public-ip-gateway"
  resource_group_name = azurerm_resource_group.smart_manufacturing.name
  location            = azurerm_resource_group.smart_manufacturing.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
  }
}

# Application Gateway
resource "azurerm_application_gateway" "app_gateway" {
  name                = "smart-manufacturing-iot-monitoring-platform-app-gateway-main"
  resource_group_name = azurerm_resource_group.smart_manufacturing.name
  location            = azurerm_resource_group.smart_manufacturing.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.public_subnet.id
  }

  frontend_port {
    name = "frontend-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.app_gateway_ip.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "backend-http-settings"
    priority                   = 1
  }

  tags = {
    Environment = var.environment
    Project     = "smart-manufacturing-iot-monitoring-platform"
  }
}