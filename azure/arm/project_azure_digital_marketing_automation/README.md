# Digital Marketing Automation Platform - Azure ARM Template

This ARM template deploys a comprehensive digital marketing automation platform on Microsoft Azure, implementing a microservices architecture for managing marketing campaigns, customer segmentation, email processing, and analytics.

## Architecture Overview

The platform consists of the following components:

- **Campaign Management API** - REST API for managing marketing campaigns and customer segments
- **Email Processing Engine** - Azure Functions for processing email campaigns and personalization
- **Customer Database** - Azure SQL Database storing customer profiles and campaign data
- **Analytics Dashboard** - Web-based dashboard for campaign performance monitoring
- **Message Queue** - Azure Service Bus for handling email campaign processing
- **File Storage** - Azure Storage Account for email templates and campaign assets
- **Load Balancer** - Azure Application Gateway with SSL termination and WAF protection

## Network Architecture

- **Virtual Network**: Single VNet with three subnets
  - Public Subnet (10.0.1.0/24): Application Gateway
  - Private Subnet (10.0.2.0/24): App Services and Functions
  - Data Subnet (10.0.3.0/24): SQL Database and Service Bus
- **Network Security Groups**: Configured for each subnet with appropriate security rules
- **Application Gateway**: Provides load balancing and SSL termination

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or PowerShell installed
- Resource group created for deployment

## Deployment Instructions

### Option 1: Azure CLI

```bash
# Login to Azure
az login

# Create resource group (if not exists)
az group create --name "rg-digital-marketing-platform" --location "East US"

# Deploy the template
az deployment group create \
  --resource-group "rg-digital-marketing-platform" \
  --template-file main.json \
  --parameters @variables.json
```

### Option 2: Azure PowerShell

```powershell
# Login to Azure
Connect-AzAccount

# Create resource group (if not exists)
New-AzResourceGroup -Name "rg-digital-marketing-platform" -Location "East US"

# Deploy the template
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-digital-marketing-platform" `
  -TemplateFile "main.json" `
  -TemplateParameterFile "variables.json"
```

### Option 3: Azure Portal

1. Navigate to Azure Portal
2. Search for "Deploy a custom template"
3. Select "Build your own template in the editor"
4. Copy and paste the contents of main.json
5. Click "Save" and fill in the required parameters
6. Click "Review + create" and then "Create"

## Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| location | Azure region for deployment | Resource Group location |
| environmentName | Environment identifier (dev/staging/prod) | prod |
| sqlAdminUsername | SQL Server administrator username | sqladmin |
| sqlAdminPassword | SQL Server administrator password | (required) |
| appServicePlanSku | App Service Plan pricing tier | S1 |
| storageAccountType | Storage account replication type | Standard_LRS |

## Post-Deployment Configuration

### 1. Configure Application Settings

Update the App Services with connection strings and application-specific settings:

```bash
# Set SQL connection string for Campaign API
az webapp config connection-string set \
  --resource-group "rg-digital-marketing-platform" \
  --name "digital-marketing-automation-platform-prod-campaign-api" \
  --connection-string-type SQLAzure \
  --settings DefaultConnection="Server=tcp