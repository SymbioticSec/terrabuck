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
      purge_soft_delete_on_destroy = true
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "smart_grid_rg" {
  name     = "smart-grid-scada-monitoring-platform-rg-main"
  location = var.location
  
  tags = {
    Environment = var.environment
    Project     = "smart-grid-scada-monitoring"
    Owner       = "grid-operations"
  }
}

# Virtual Network for SCADA Operations
resource "azurerm_virtual_network" "scada_vnet" {
  name                = "smart-grid-scada-monitoring-platform-vnet-operations"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.smart_grid_rg.location
  resource_group_name = azurerm_resource_group.smart_grid_rg.name

  tags = {
    Environment = var.environment
    Zone        = "scada_operations"
  }
}

# Subnet for IoT Hub
resource "azurerm_subnet" "iot_subnet" {
  name                 = "smart-grid-scada-monitoring-platform-subnet-iot"
  resource_group_name  = azurerm_resource_group.smart_grid_rg.name
  virtual_network_name = azurerm_virtual_network.scada_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for Data Services
resource "azurerm_subnet" "data_subnet" {
  name                 = "smart-grid-scada-monitoring-platform-subnet-data"
  resource_group_name  = azurerm_resource_group.smart_grid_rg.name
  virtual_network_name = azurerm_virtual_network.scada_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Group for IoT
resource "azurerm_network_security_group" "iot_nsg" {
  name                = "smart-grid-scada-monitoring-platform-nsg-iot"
  location            = azurerm_resource_group.smart_grid_rg.location
  resource_group_name = azurerm_resource_group.smart_grid_rg.name

  security_rule {
    name                       = "AllowIoTTraffic"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8883"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Key Vault for SCADA Secrets
resource "azurerm_key_vault" "scada_kv" {
  name                = "smart-grid-scada-kv-${random_string.suffix.result}"
  location            = azurerm_resource_group.smart_grid_rg.location
  resource_group_name = azurerm_resource_group.smart_grid_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }
}

# IoT Hub Device Connection String Secret (VULNERABLE - No expiration)
resource "azurerm_key_vault_secret" "iot_connection_string" {
  name         = "iot-hub-connection-string"
  value        = "HostName=${azurerm_iothub.scada_iot_hub.hostname};SharedAccessKeyName=iothubowner;SharedAccessKey=dummy-key-for-scada-devices"
  key_vault_id = azurerm_key_vault.scada_kv.id
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Data source for current client config
data "azurerm_client_config" "current" {}

# IoT Hub for SCADA telemetry ingestion
resource "azurerm_iothub" "scada_iot_hub" {
  name                = "smart-grid-scada-monitoring-platform-iothub-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.smart_grid_rg.name
  location            = azurerm_resource_group.smart_grid_rg.location

  sku {
    name     = "S1"
    capacity = "2"
  }

  endpoint {
    type                       = "AzureIotHub.StorageContainer"
    connection_string          = azurerm_storage_account.notification_storage.primary_blob_connection_string
    name                       = "scada-telemetry-export"
    batch_frequency_in_seconds = 60
    max_chunk_size_in_bytes    = 10485760
    container_name             = azurerm_storage_container.telemetry_container.name
    encoding                   = "Avro"
    file_name_format           = "{iothub}/{partition}_{YYYY}_{MM}_{DD}_{HH}_{mm}"
  }

  route {
    name           = "scada-telemetry-route"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["scada-telemetry-export"]
    enabled        = true
  }

  tags = {
    Environment = var.environment
    Component   = "iot_hub"
  }
}

# Storage Account for notifications (VULNERABLE - HTTP allowed)
resource "azurerm_storage_account" "notification_storage" {
  name                     = "smartgridscada${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.smart_grid_rg.name
  location                 = azurerm_resource_group.smart_grid_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = false

  tags = {
    Environment = var.environment
    Component   = "notification_storage"
  }
}

# Storage Account Network Rules (VULNERABLE - Allow all)
resource "azurerm_storage_account_network_rules" "notification_storage_rules" {
  storage_account_id = azurerm_storage_account.notification_storage.id
  default_action     = "Allow"
  ip_rules           = ["127.0.0.1"]
  bypass             = ["Metrics", "Logging"]
}

# Storage Container for telemetry data
resource "azurerm_storage_container" "telemetry_container" {
  name                  = "scada-telemetry-data"
  storage_account_name  = azurerm_storage_account.notification_storage.name
  container_access_type = "private"
}

# Data Explorer Cluster for time-series database
resource "azurerm_kusto_cluster" "time_series_database" {
  name                = "smart-grid-scada-monitoring-platform-adx-${random_string.suffix.result}"
  location            = azurerm_resource_group.smart_grid_rg.location
  resource_group_name = azurerm_resource_group.smart_grid_rg.name

  sku {
    name     = "Dev(No SLA)_Standard_D11_v2"
    capacity = 1
  }

  tags = {
    Environment = var.environment
    Component   = "time_series_database"
  }
}

# Data Explorer Database
resource "azurerm_kusto_database" "scada_telemetry_db" {
  name                = "scada-telemetry-database"
  resource_group_name = azurerm_resource_group.smart_grid_rg.name
  location            = azurerm_resource_group.smart_grid_rg.location
  cluster_name        = azurerm_kusto_cluster.time_series_database.name
}

# App Service Plan for Functions and Web App
resource "azurerm_service_plan" "scada_plan" {
  name                = "smart-grid-scada-monitoring-platform-plan-main"
  resource_group_name = azurerm_resource_group.smart_grid_rg.name
  location            = azurerm_resource_group.smart_grid_rg.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

# Function App for alert processing (VULNERABLE - No HTTPS enforcement)
resource "azurerm_linux_function_app" "alert_processor" {
  name                = "smart-grid-scada-monitoring-platform-func-alerts-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.smart_grid_rg.name
  location            = azurerm_resource_group.smart_grid_rg.location

  storage_account_name       = azurerm_storage_account.notification_storage.name
  storage_account_access_key = azurerm_storage_account.notification_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.scada_plan.id

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "ADX_CONNECTION_STRING"    = azurerm_kusto_cluster.time_series_database.uri
  }

  tags = {
    Environment = var.environment
    Component   = "alert_processor"
  }
}

# App Service for operator dashboard (VULNERABLE - No managed identity)
resource "azurerm_linux_web_app" "operator_dashboard" {
  name                = "smart-grid-scada-monitoring-platform-app-dashboard-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.smart_grid_rg.name
  location            = azurerm_resource_group.smart_grid_rg.location
  service_plan_id     = azurerm_service_plan.scada_plan.id

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }

  app_settings = {
    "ADX_CLUSTER_URI"          = azurerm_kusto_cluster.time_series_database.uri
    "STORAGE_CONNECTION_STRING" = azurerm_storage_account.notification_storage.primary_connection_string
  }

  tags = {
    Environment = var.environment
    Component   = "operator_dashboard"
  }
}

# Stream Analytics Job for real-time processing
resource "azurerm_stream_analytics_job" "stream_processor" {
  name                                     = "smart-grid-scada-monitoring-platform-asa-processor"
  resource_group_name                      = azurerm_resource_group.smart_grid_rg.name
  location                                 = azurerm_resource_group.smart_grid_rg.location
  compatibility_level                      = "1.2"
  data_locale                             = "en-GB"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy              = "Adjust"
  output_error_policy                     = "Drop"
  streaming_units                         = 3

  tags = {
    Environment = var.environment
    Component   = "stream_processor"
  }

  transformation_query = <<QUERY
SELECT
    DeviceId,
    EventTime,
    Temperature,
    Voltage,
    Current,
    System.Timestamp() as ProcessedTime
INTO
    [scada-output]
FROM
    [scada-input]
WHERE
    Temperature > 75 OR Voltage < 220
QUERY
}

# Monitor Log Profile (VULNERABLE - Short retention)
resource "azurerm_monitor_log_profile" "scada_monitoring" {
  name = "smart-grid-scada-monitoring-platform-logprofile-main"

  categories = [
    "Action",
    "Delete",
    "Write",
  ]

  locations = [
    "westus",
    "global",
  ]

  storage_account_id = azurerm_storage_account.notification_storage.id

  retention_policy {
    enabled = true
    days    = 7
  }
}

# Security Center Contact (VULNERABLE - Missing phone)
resource "azurerm_security_center_contact" "scada_security_contact" {
  email = var.security_contact_email
  phone = ""

  alert_notifications = true
  alerts_to_admins    = true
}