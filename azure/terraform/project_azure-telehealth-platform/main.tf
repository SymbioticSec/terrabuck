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
resource "azurerm_resource_group" "telehealth_rg" {
  name     = "telehealth-video-consultation-platform-rg-main"
  location = var.location
  
  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
    Purpose     = "HIPAA-compliant telehealth platform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "telehealth_vnet" {
  name                = "telehealth-video-consultation-platform-vnet-main"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.telehealth_rg.location
  resource_group_name = azurerm_resource_group.telehealth_rg.name

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
  }
}

# Public Subnet for Application Gateway
resource "azurerm_subnet" "public_subnet" {
  name                 = "telehealth-video-consultation-platform-subnet-public"
  resource_group_name  = azurerm_resource_group.telehealth_rg.name
  virtual_network_name = azurerm_virtual_network.telehealth_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private Subnet for App Services
resource "azurerm_subnet" "private_subnet" {
  name                 = "telehealth-video-consultation-platform-subnet-private"
  resource_group_name  = azurerm_resource_group.telehealth_rg.name
  virtual_network_name = azurerm_virtual_network.telehealth_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  
  delegation {
    name = "app-service-delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Data Subnet for Database
resource "azurerm_subnet" "data_subnet" {
  name                 = "telehealth-video-consultation-platform-subnet-data"
  resource_group_name  = azurerm_resource_group.telehealth_rg.name
  virtual_network_name = azurerm_virtual_network.telehealth_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Network Security Group with vulnerable SSH rule
resource "azurerm_network_security_group" "telehealth_nsg" {
  name                = "telehealth-video-consultation-platform-nsg-main"
  location            = azurerm_resource_group.telehealth_rg.location
  resource_group_name = azurerm_resource_group.telehealth_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"  # VULNERABILITY: SSH_BLOCKED_FROM_INTERNET
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
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
    Project     = "telehealth-video-consultation-platform"
  }
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "app_gateway_pip" {
  name                = "telehealth-video-consultation-platform-pip-appgw"
  resource_group_name = azurerm_resource_group.telehealth_rg.name
  location            = azurerm_resource_group.telehealth_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
  }
}

# Application Gateway (web_application_gateway component)
resource "azurerm_application_gateway" "telehealth_app_gateway" {
  name                = "telehealth-video-consultation-platform-appgw-main"
  resource_group_name = azurerm_resource_group.telehealth_rg.name
  location            = azurerm_resource_group.telehealth_rg.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
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

  frontend_port {
    name = "frontend-port-443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.app_gateway_pip.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
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

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
  }
}

# Storage Account for Medical Records (medical_records_storage component)
resource "azurerm_storage_account" "medical_records_storage" {
  name                     = "telehealthmedicalrecs${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.telehealth_rg.name
  location                 = azurerm_resource_group.telehealth_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  # VULNERABILITY: ENFORCE_HTTPS - Not enforcing HTTPS
  enable_https_traffic_only = false
  
  # VULNERABILITY: USE_SECURE_TLS_POLICY - Using insecure TLS version
  min_tls_version = "TLS1_0"

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
    Purpose     = "medical-records-storage"
  }
}

resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Storage Container for Medical Records
resource "azurerm_storage_container" "medical_records_container" {
  name                  = "medical-records"
  storage_account_name  = azurerm_storage_account.medical_records_storage.name
  container_access_type = "private"
}

# SQL Server (consultation_database component)
resource "azurerm_mssql_server" "consultation_sql_server" {
  name                         = "telehealth-video-consultation-platform-sql-${random_string.sql_suffix.result}"
  resource_group_name          = azurerm_resource_group.telehealth_rg.name
  location                     = azurerm_resource_group.telehealth_rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  
  # VULNERABILITY: DATABASE-NO_PUBLIC_ACCESS - Enabling public network access
  public_network_access_enabled = true

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
  }
}

resource "random_string" "sql_suffix" {
  length  = 8
  special = false
  upper   = false
}

# SQL Database
resource "azurerm_mssql_database" "consultation_database" {
  name           = "consultation-db"
  server_id      = azurerm_mssql_server.consultation_sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 100
  sku_name       = "S2"
  zone_redundant = false

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
  }
}

# SQL Server Security Alert Policy with missing email configuration
resource "azurerm_mssql_server_security_alert_policy" "consultation_sql_alert_policy" {
  resource_group_name = azurerm_resource_group.telehealth_rg.name
  server_name         = azurerm_mssql_server.consultation_sql_server.name
  state               = "Enabled"
  
  # VULNERABILITY: THREAT_ALERT_EMAIL_SET - Empty email addresses
  email_addresses = []
  
  disabled_alerts = [
    "Sql_Injection",
    "Data_Exfiltration"
  ]
}

# App Service Plan
resource "azurerm_service_plan" "consultation_app_plan" {
  name                = "telehealth-video-consultation-platform-plan-main"
  resource_group_name = azurerm_resource_group.telehealth_rg.name
  location            = azurerm_resource_group.telehealth_rg.location
  os_type             = "Linux"
  sku_name            = "P1v2"

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
  }
}

# App Service (consultation_web_app component)
resource "azurerm_linux_web_app" "consultation_web_app" {
  name                = "telehealth-video-consultation-platform-webapp-${random_string.webapp_suffix.result}"
  resource_group_name = azurerm_resource_group.telehealth_rg.name
  location            = azurerm_service_plan.consultation_app_plan.location
  service_plan_id     = azurerm_service_plan.consultation_app_plan.id

  site_config {
    always_on = true
    
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DATABASE_CONNECTION_STRING"          = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.telehealth_kv.name};SecretName=database-connection-string)"
  }

  https_only = true

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
  }
}

resource "random_string" "webapp_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Media Services Account (video_streaming_service component)
resource "azurerm_media_services_account" "video_streaming_service" {
  name                = "telehealthmedia${random_string.media_suffix.result}"
  location            = azurerm_resource_group.telehealth_rg.location
  resource_group_name = azurerm_resource_group.telehealth_rg.name

  storage_account {
    id         = azurerm_storage_account.media_storage.id
    is_primary = true
  }

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
    Purpose     = "video-streaming-service"
  }
}

resource "random_string" "media_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Storage Account for Media Services
resource "azurerm_storage_account" "media_storage" {
  name                     = "telehealthmedia${random_string.media_storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.telehealth_rg.name
  location                 = azurerm_resource_group.telehealth_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = true

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
  }
}

resource "random_string" "media_storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Function App Storage Account
resource "azurerm_storage_account" "function_storage" {
  name                     = "telehealthfunc${random_string.func_storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.telehealth_rg.name
  location                 = azurerm_resource_group.telehealth_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = true

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
  }
}

resource "random_string" "func_storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Function App (notification_service component)
resource "azurerm_linux_function_app" "notification_service" {
  name                = "telehealth-video-consultation-platform-func-${random_string.function_suffix.result}"
  resource_group_name = azurerm_resource_group.telehealth_rg.name
  location            = azurerm_resource_group.telehealth_rg.location

  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.consultation_app_plan.id

  # VULNERABILITY: APPSERVICE-ENFORCE_HTTPS - Not enforcing HTTPS only
  # https_only parameter is omitted, defaulting to false

  site_config {
    application_stack {
      node_version = "18"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "node"
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
    "DATABASE_CONNECTION_STRING"   = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.telehealth_kv.name};SecretName=database-connection-string)"
  }

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
    Purpose     = "notification-service"
  }
}

resource "random_string" "function_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Key Vault for secrets management
resource "azurerm_key_vault" "telehealth_kv" {
  name                = "telehealth-kv-${random_string.kv_suffix.result}"
  location            = azurerm_resource_group.telehealth_rg.location
  resource_group_name = azurerm_resource_group.telehealth_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore"
    ]
  }

  tags = {
    Environment = var.environment
    Project     = "telehealth-video-consultation-platform"
  }
}

resource "random_string" "kv_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Monitor Log Profile with incomplete categories
resource "azurerm_monitor_log_profile" "telehealth_log_profile" {
  name = "telehealth-video-consultation-platform-logprofile-main"

  # VULNERABILITY: CAPTURE_ALL_ACTIVITIES - Missing critical categories
  categories = []

  locations = [
    azurerm_resource_group.telehealth_rg.location,
  ]

  storage_account_id = azurerm_storage_account.medical_records_storage.id

  retention_policy {
    enabled = true
    days    = 7
  }
}

data "azurerm_client_config" "current" {}