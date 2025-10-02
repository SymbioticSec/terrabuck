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
resource "azurerm_resource_group" "healthcare_portal" {
  name     = "healthcare-patient-portal-with-hipaa-compliance-rg-main"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
    Compliance  = "HIPAA"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "healthcare_vnet" {
  name                = "healthcare-patient-portal-with-hipaa-compliance-vnet-hub"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.healthcare_portal.location
  resource_group_name = azurerm_resource_group.healthcare_portal.name

  tags = {
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
  }
}

# Public Subnet for Web Frontend
resource "azurerm_subnet" "public_subnet" {
  name                 = "healthcare-patient-portal-with-hipaa-compliance-subnet-public"
  resource_group_name  = azurerm_resource_group.healthcare_portal.name
  virtual_network_name = azurerm_virtual_network.healthcare_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private Subnet for Backend Services
resource "azurerm_subnet" "private_subnet" {
  name                 = "healthcare-patient-portal-with-hipaa-compliance-subnet-private"
  resource_group_name  = azurerm_resource_group.healthcare_portal.name
  virtual_network_name = azurerm_virtual_network.healthcare_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Data Subnet for Database
resource "azurerm_subnet" "data_subnet" {
  name                 = "healthcare-patient-portal-with-hipaa-compliance-subnet-data"
  resource_group_name  = azurerm_resource_group.healthcare_portal.name
  virtual_network_name = azurerm_virtual_network.healthcare_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Network Security Group for Backend Services - VULNERABLE: Allows public ingress
resource "azurerm_network_security_group" "backend_nsg" {
  name                = "healthcare-patient-portal-with-hipaa-compliance-nsg-backend"
  location            = azurerm_resource_group.healthcare_portal.location
  resource_group_name = azurerm_resource_group.healthcare_portal.name

  security_rule {
    name                       = "allow_backend_access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
  }
}

# Associate NSG with Private Subnet
resource "azurerm_subnet_network_security_group_association" "private_nsg_association" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

# Storage Account for File Storage - VULNERABLE: Weak TLS policy
resource "azurerm_storage_account" "file_storage" {
  name                     = "healthcarepatientportalst"
  resource_group_name      = azurerm_resource_group.healthcare_portal.name
  location                 = azurerm_resource_group.healthcare_portal.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_0"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
    Purpose     = "medical-documents"
  }
}

# Storage Container for Medical Documents
resource "azurerm_storage_container" "medical_documents" {
  name                  = "medical-documents"
  storage_account_name  = azurerm_storage_account.file_storage.name
  container_access_type = "private"
}

# Key Vault for Secrets Management
resource "azurerm_key_vault" "healthcare_kv" {
  name                = "healthcare-portal-kv-${random_string.kv_suffix.result}"
  location            = azurerm_resource_group.healthcare_portal.location
  resource_group_name = azurerm_resource_group.healthcare_portal.name
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
      "Purge"
    ]
  }

  tags = {
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
  }
}

# Random string for Key Vault naming
resource "random_string" "kv_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Key Vault Secret for Database Connection - VULNERABLE: No expiration date
resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "database-connection-string"
  value        = "Server=${azurerm_mssql_server.patient_db.fully_qualified_domain_name};Database=${azurerm_mssql_database.patient_database.name};User ID=${var.db_admin_username};Password=${var.db_admin_password};"
  key_vault_id = azurerm_key_vault.healthcare_kv.id

  tags = {
    Environment = var.environment
    Purpose     = "database-access"
  }
}

# Key Vault Secret for API Keys - VULNERABLE: No expiration date
resource "azurerm_key_vault_secret" "api_gateway_key" {
  name         = "api-gateway-primary-key"
  value        = "healthcare-api-key-${random_string.api_key.result}"
  key_vault_id = azurerm_key_vault.healthcare_kv.id

  tags = {
    Environment = var.environment
    Purpose     = "api-authentication"
  }
}

# Random string for API key
resource "random_string" "api_key" {
  length  = 32
  special = true
}

# SQL Server for Patient Database - VULNERABLE: Public access enabled, SSL not enforced
resource "azurerm_mssql_server" "patient_db" {
  name                         = "healthcare-patient-portal-with-hipaa-compliance-sqlserver-main"
  resource_group_name          = azurerm_resource_group.healthcare_portal.name
  location                     = azurerm_resource_group.healthcare_portal.location
  version                      = "12.0"
  administrator_login          = var.db_admin_username
  administrator_login_password = var.db_admin_password
  public_network_access_enabled = true

  tags = {
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
    DataType    = "PHI"
  }
}

# SQL Database for Patient Records
resource "azurerm_mssql_database" "patient_database" {
  name      = "healthcare-patient-portal-with-hipaa-compliance-database-patients"
  server_id = azurerm_mssql_server.patient_db.id
  sku_name  = "S1"

  tags = {
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
    DataType    = "PHI"
  }
}

# SQL Server Security Alert Policy - VULNERABLE: Critical alerts disabled
resource "azurerm_mssql_server_security_alert_policy" "patient_db_alerts" {
  resource_group_name = azurerm_resource_group.healthcare_portal.name
  server_name         = azurerm_mssql_server.patient_db.name
  state               = "Enabled"
  storage_endpoint    = azurerm_storage_account.file_storage.primary_blob_endpoint
  storage_account_access_key = azurerm_storage_account.file_storage.primary_access_key
  disabled_alerts = [
    "Sql_Injection",
    "Data_Exfiltration"
  ]
  retention_days = 20
}

# App Service Plan for Web Frontend
resource "azurerm_service_plan" "web_plan" {
  name                = "healthcare-patient-portal-with-hipaa-compliance-plan-web"
  resource_group_name = azurerm_resource_group.healthcare_portal.name
  location            = azurerm_resource_group.healthcare_portal.location
  os_type             = "Linux"
  sku_name            = "P1v2"

  tags = {
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
  }
}

# App Service for Web Frontend - VULNERABLE: Weak TLS policy
resource "azurerm_linux_web_app" "web_frontend" {
  name                = "healthcare-patient-portal-with-hipaa-compliance-webapp-frontend"
  resource_group_name = azurerm_resource_group.healthcare_portal.name
  location            = azurerm_service_plan.web_plan.location
  service_plan_id     = azurerm_service_plan.web_plan.id

  site_config {
    minimum_tls_version = "1.0"
    
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "API_GATEWAY_URL" = "https://${azurerm_api_management.healthcare_apim.gateway_url}"
    "ENVIRONMENT"     = var.environment
  }

  tags = {
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
    Component   = "web-frontend"
  }
}

# API Management Service
resource "azurerm_api_management" "healthcare_apim" {
  name                = "healthcare-patient-portal-with-hipaa-compliance-apim-gateway"
  location            = azurerm_resource_group.healthcare_portal.location
  resource_group_name = azurerm_resource_group.healthcare_portal.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = "Developer_1"

  tags = {
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
    Component   = "api-gateway"
  }
}

# Container Group for Backend Services - VULNERABLE: No logging configuration
resource "azurerm_container_group" "backend_services" {
  name                = "healthcare-patient-portal-with-hipaa-compliance-container-backend"
  location            = azurerm_resource_group.healthcare_portal.location
  resource_group_name = azurerm_resource_group.healthcare_portal.name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.private_subnet.id]
  os_type             = "Linux"

  container {
    name   = "patient-api"
    image  = "nginx:latest"
    cpu    = "1"
    memory = "2"

    ports {
      port     = 8080
      protocol = "TCP"
    }

    environment_variables = {
      "DATABASE_CONNECTION" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_connection_string.id})"
      "ENVIRONMENT"         = var.environment
    }
  }

  container {
    name   = "appointment-service"
    image  = "nginx:latest"
    cpu    = "0.5"
    memory = "1"

    ports {
      port     = 8081
      protocol = "TCP"
    }
  }

  tags = {
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
    Component   = "backend-services"
  }
}

# Data sources
data "azurerm_client_config" "current" {}