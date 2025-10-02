# Multi-Tenant E-Commerce Platform - Azure ARM Template

This ARM template deploys a complete multi-tenant e-commerce platform on Azure, designed for SaaS providers offering e-commerce services to small and medium businesses.

## Architecture Overview

The platform implements a scalable, multi-tenant architecture with the following components:

- **Application Gateway**: Provides SSL termination, tenant routing, and WAF protection
- **App Service**: Hosts the multi-tenant web application with tenant isolation
- **SQL Database**: Stores tenant configurations, product catalogs, and order data
- **Storage Account**: Manages product images, tenant assets, and reports
- **Redis Cache**: Handles session management and product catalog caching
- **Azure Functions**: Processes payments and handles webhook validation
- **Virtual Network**: Provides network isolation with public, private, and data subnets

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or PowerShell installed
- Resource group created for deployment

## Deployment Instructions

### Using Azure CLI

1. **Clone or download the template files**
   ```bash
   # Ensure you have main.json and variables.json in the same directory
   ```

2. **Create a resource group** (if not already created)
   ```bash
   az group create --name "rg-ecommerce-platform" --location "East US"
   ```

3. **Deploy the template**
   ```bash
   az deployment group create \
     --resource-group "rg-ecommerce-platform" \
     --template-file main.json \
     --parameters @variables.json
   ```

### Using Azure PowerShell

1. **Create a resource group** (if not already created)
   ```powershell
   New-AzResourceGroup -Name "rg-ecommerce-platform" -Location "East US"
   ```

2. **Deploy the template**
   ```powershell
   New-AzResourceGroupDeployment `
     -ResourceGroupName "rg-ecommerce-platform" `
     -TemplateFile "main.json" `
     -TemplateParameterFile "variables.json"
   ```

### Using Azure Portal

1. Navigate to the Azure Portal
2. Search for "Deploy a custom template"
3. Select "Build your own template in the editor"
4. Copy and paste the contents of `main.json`
5. Click "Save" and fill in the required parameters
6. Review and create the deployment

## Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| `location` | Azure region for deployment | Resource group location |
| `environmentName` | Environment identifier (dev/staging/prod) | prod |
| `sqlAdminUsername` | SQL Server administrator username | sqladmin |
| `sqlAdminPassword` | SQL Server administrator password | *Required* |