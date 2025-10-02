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
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "dr_platform" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.primary_location

  tags = var.common_tags
}

# Secondary Resource Group for DR
resource "azurerm_resource_group" "dr_platform_secondary" {
  name     = "rg-${var.project_name}-${var.environment}-dr"
  location = var.secondary_location

  tags = var.common_tags
}

# Virtual Network - Primary Region
resource "azurerm_virtual_network" "dr_vnet_primary" {
  name                = "vnet-${var.project_name}-${var.environment}-primary"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.dr_platform.location
  resource_group_name = azurerm_resource_group.dr_platform.name

  tags = var.common_tags
}

# Virtual Network - Secondary Region
resource "azurerm_virtual_network" "dr_vnet_secondary" {
  name                = "vnet-${var.project_name}-${var.environment}-secondary"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.dr_platform_secondary.location
  resource_group_name = azurerm_resource_group.dr_platform_secondary.name

  tags = var.common_tags
}

# Subnets
resource "azurerm_subnet" "web_subnet" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.dr_platform.name
  virtual_network_name = azurerm_virtual_network.dr_vnet_primary.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "compute_subnet" {
  name                 = "snet-compute"
  resource_group_name  = azurerm_resource_group.dr_platform.name
  virtual_network_name = azurerm_virtual_network.dr_vnet_primary.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "data_subnet" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.dr_platform.name
  virtual_network_name = azurerm_virtual_network.dr_vnet_primary.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Log Analytics Workspace - Monitoring Analytics Component
resource "azurerm_log_analytics_workspace" "monitoring_analytics" {
  name                = "law-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.dr_platform.location
  resource_group_name = azurerm_resource_group.dr_platform.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.common_tags
}

# Storage Account - Backup Storage Component (VULNERABLE: Weak TLS)
resource "azurerm_storage_account" "backup_storage" {
  name                     = "st${var.project_name}backup${var.environment}"
  resource_group_name      = azurerm_resource_group.dr_platform.name
  location                 = azurerm_resource_group.dr_platform.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_0"

  network_rules {
    default_action = "Deny"
    ip_rules       = ["0.0.0.0/0"]
    bypass         = ["Metrics"]
  }

  tags = var.common_tags
}

# Storage Container for Backups
resource "azurerm_storage_container" "backup_container" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.backup_storage.name
  container_access_type = "private"
}

# SQL Server for Recovery Database
resource "azurerm_mssql_server" "recovery_sql_server" {
  name                         = "sql-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.dr_platform.name
  location                     = azurerm_resource_group.dr_platform.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.1"

  tags = var.common_tags
}

# SQL Database - Recovery Database Component
resource "azurerm_mssql_database" "recovery_database" {
  name           = "sqldb-${var.project_name}-recovery-${var.environment}"
  server_id      = azurerm_mssql_server.recovery_sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 100
  sku_name       = "S2"
  zone_redundant = false

  tags = var.common_tags
}

# SQL Server Security Alert Policy (VULNERABLE: Disabled alerts)
resource "azurerm_mssql_server_security_alert_policy" "recovery_db_alerts" {
  resource_group_name        = azurerm_resource_group.dr_platform.name
  server_name                = azurerm_mssql_server.recovery_sql_server.name
  state                      = "Enabled"
  storage_endpoint           = azurerm_storage_account.backup_storage.primary_blob_endpoint
  storage_account_access_key = azurerm_storage_account.backup_storage.primary_access_key
  disabled_alerts = [
    "Sql_Injection",
    "Data_Exfiltration"
  ]
  retention_days = 20
}

# App Service Plan for Web Portal and Functions
resource "azurerm_service_plan" "dr_service_plan" {
  name                = "asp-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.dr_platform.name
  location            = azurerm_resource_group.dr_platform.location
  os_type             = "Linux"
  sku_name            = "P1v2"

  tags = var.common_tags
}

# Storage Account for Function App
resource "azurerm_storage_account" "function_storage" {
  name                     = "st${var.project_name}func${var.environment}"
  resource_group_name      = azurerm_resource_group.dr_platform.name
  location                 = azurerm_resource_group.dr_platform.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.common_tags
}

# Function App - DR Orchestration Engine Component (VULNERABLE: No managed identity, no HTTPS)
resource "azurerm_linux_function_app" "dr_orchestration_engine" {
  name                = "func-${var.project_name}-orchestration-${var.environment}"
  resource_group_name = azurerm_resource_group.dr_platform.name
  location            = azurerm_resource_group.dr_platform.location

  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.dr_service_plan.id

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "python"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.dr_insights.instrumentation_key
  }

  tags = var.common_tags
}

# App Service - DR Web Portal Component (VULNERABLE: No authentication, no HTTPS)
resource "azurerm_linux_web_app" "dr_web_portal" {
  name                = "app-${var.project_name}-portal-${var.environment}"
  resource_group_name = azurerm_resource_group.dr_platform.name
  location            = azurerm_resource_group.dr_platform.location
  service_plan_id     = azurerm_service_plan.dr_service_plan.id

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.dr_insights.instrumentation_key
  }

  tags = var.common_tags
}

# Application Insights
resource "azurerm_application_insights" "dr_insights" {
  name                = "appi-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.dr_platform.location
  resource_group_name = azurerm_resource_group.dr_platform.name
  workspace_id        = azurerm_log_analytics_workspace.monitoring_analytics.id
  application_type    = "web"

  tags = var.common_tags
}

# Communication Services - Notification Service Component
resource "azurerm_communication_service" "notification_service" {
  name                = "cs-${var.project_name}-notifications-${var.environment}"
  resource_group_name = azurerm_resource_group.dr_platform.name
  data_location       = "United States"

  tags = var.common_tags
}

# Monitor Log Profile (VULNERABLE: Empty categories)
resource "azurerm_monitor_log_profile" "dr_log_profile" {
  name = "logprofile-${var.project_name}-${var.environment}"

  categories = []

  locations = [
    azurerm_resource_group.dr_platform.location,
    azurerm_resource_group.dr_platform_secondary.location,
  ]

  storage_account_id = azurerm_storage_account.backup_storage.id

  retention_policy {
    enabled = true
    days    = 7
  }
}

# Network Security Group for Web Subnet
resource "azurerm_network_security_group" "web_nsg" {
  name                = "nsg-web-${var.environment}"
  location            = azurerm_resource_group.dr_platform.location
  resource_group_name = azurerm_resource_group.dr_platform.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.common_tags
}

# Network Security Group for Data Subnet
resource "azurerm_network_security_group" "data_nsg" {
  name                = "nsg-data-${var.environment}"
  location            = azurerm_resource_group.dr_platform.location
  resource_group_name = azurerm_resource_group.dr_platform.name

  security_rule {
    name                       = "AllowSQL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  tags = var.common_tags
}

# Subnet NSG Associations
resource "azurerm_subnet_network_security_group_association" "web_nsg_association" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "data_nsg_association" {
  subnet_id                 = azurerm_subnet.data_subnet.id
  network_security_group_id = azurerm_network_security_group.data_nsg.id
}