# Legal Document Management Platform - Azure ARM Template

## Overview

This ARM template deploys a comprehensive legal document management platform on Azure, designed for mid-sized law firms (50-200 employees) to digitize their document management process while ensuring client confidentiality and regulatory compliance.

## Architecture Components

### Core Services
- **Web Application**: Azure App Service hosting the main document management interface
- **Document Storage**: Azure Storage Account with blob storage for legal documents
- **Application Database**: Azure SQL Database for metadata, user information, and audit logs
- **Search Service**: Azure Cognitive Search for full-text search capabilities
- **Document Processor**: Azure Functions for serverless document processing and OCR
- **Application Gateway**: WAF-enabled gateway with SSL termination and load balancing

### Network Architecture
- **Virtual Network**: Segmented into public, private, and data subnets
- **Network Security Groups**: Controlling traffic flow between tiers
- **Private Endpoints**: Secure connectivity to data services
- **VNet Integration**: App services connected to private subnets

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or PowerShell installed
- Resource group created for deployment

## Deployment Instructions

### 1. Clone or Download Template Files

Ensure you have the following files:
- `main.json` - Main ARM template
- `variables.json` - Parameter values
- `outputs.json` - Output definitions

### 2. Update Parameters

Edit the `variables.json` file to customize deployment:

```json
{
  "parameters": {
    "location": {
      "value": "East US"  // Change to your preferred region
    },
    "environmentName": {
      "value": "prod"     // dev, test, or prod
    },
    "sqlAdminPassword": {
      "value": "YourSecurePassword123!"  // Use a strong password
    }
  }
}
```

### 3. Deploy Using Azure CLI

```bash
# Login to Azure
az login

# Set subscription (if needed)
az account set --subscription "your-subscription-id"

# Create resource group
az group create --name "rg-legal-docmgmt-prod" --location "East US"

# Deploy template
az deployment group create \
  --resource-group "rg-legal-docmgmt-prod" \
  --template-file main.json \
  --parameters @variables.json
```

### 4. Deploy Using PowerShell

```powershell
# Login to Azure
Connect-AzAccount

# Set subscription (if needed)
Set-AzContext -SubscriptionId "your-subscription-id"

# Create resource group
New-AzResourceGroup -Name "rg-legal-docmgmt-prod" -Location "East US"

# Deploy template