# Restaurant POS and Inventory Management System

This ARM template deploys a comprehensive cloud-based Point of Sale system for restaurant chains with real-time inventory management, sales analytics, and multi-location support.

## Architecture Overview

The system implements a microservices architecture with the following components:

- **Application Gateway**: Load balancer with WAF capabilities for SSL termination and traffic distribution
- **Web Application**: Frontend POS interface for tablets and desktop management dashboards
- **API Backend**: RESTful API handling order processing, inventory, and user management
- **Payment Functions**: Serverless functions for payment processing integration
- **SQL Database**: Primary database for menu items, orders, transactions, and inventory
- **Storage Accounts**: Blob storage for inventory images and secure transaction logs
- **Monitoring**: Application Insights and Log Analytics for system monitoring

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or PowerShell installed
- Resource group created for deployment

## Deployment Instructions

### Using Azure CLI

1. Clone this repository and navigate to the template directory
2. Create a resource group:
   ```bash
   az group create --name restaurant-pos-rg --location "East US"
   ```

3. Deploy the template:
   ```bash
   az deployment group create \
     --resource-group restaurant-pos-rg \
     --template-file main.json \
     --parameters @variables.json
   ```

### Using PowerShell

1. Connect to Azure:
   ```powershell
   Connect-AzAccount
   ```

2. Create a resource group:
   ```powershell
   New-AzResourceGroup -Name "restaurant-pos-rg" -Location "East US"
   ```

3. Deploy the template:
   ```powershell
   New-AzResourceGroupDeployment `
     -ResourceGroupName "restaurant-pos-rg" `
     -TemplateFile "main.json" `
     -TemplateParameterFile "variables.json"
   ```

## Configuration

### Parameters

- **location**: Azure region for resource deployment (default: resource group location)
- **environmentName**: Environment identifier for resource naming (default: "prod")
- **sqlAdminUsername**: SQL Server administrator username (default: "posadmin")
- **sqlAdminPassword**: SQL Server administrator password (required, secure string)
- **appServicePlanSku**: App Service Plan pricing tier (default: "S1")

### Post-Deployment Configuration

1. **Database Setup**: Connect to the SQL database and run initialization scripts for menu items, user accounts, and inventory tables
2. **Application Configuration**: Update App Service application settings with database connection strings and API keys
3. **SSL Certificates**: Configure custom SSL certificates in Application Gateway for production domains
4. **Payment Integration**: Configure payment gateway credentials in Azure Functions
5. **Monitoring**: Set up alerts and dashboards in Application Insights

## Security Considerations

This template implements several security measures:

- HTTPS enforcement on App Services
- Network security groups with restricted access
- SQL Database with security alert policies
- Storage account encryption
- Application Insights for monitoring and alerting

## Networking

The template creates a virtual network with three subnets:
- **Public Subnet (10.0.1.0/24)**: Application Gateway
- **Private Subnet (10.0.2.0/24)**: App Services and Functions
- **Data Subnet (10.0.3.0/24)**: SQL Database (future private endpoint)

## Monitoring and Logging

- **Application Insights**: Application performance monitoring and user analytics
- **Log Analytics**: Centralized logging and query capabilities
- **Activity Log Alerts**: Monitoring of administrative activities
- **SQL Security Alerts**: Database threat detection and alerting

## Scaling Considerations

- App Service Plan can be scaled up/out based on demand
- Application Gateway supports auto-scaling
- SQL Database can be scaled to higher service tiers
- Storage accounts provide virtually unlimited capacity

## Cost Optimization

- Review App Service Plan sizing based on actual usage
- Consider Azure Functions consumption plan for payment processing
- Implement storage lifecycle policies for log retention
- Monitor and optimize SQL Database DTU usage

## Support and Maintenance

- Regular security updates for App Services
- Database backup and recovery procedures
- Storage account lifecycle management
- Performance monitoring and optimization

## Troubleshooting

Common issues and solutions:

1. **Deployment Failures**: Check resource naming constraints and regional availability
2. **Database Connectivity**: Verify firewall rules and connection strings
3. **Application Gateway**: Ensure backend health probe configuration
4. **Storage Access**: Verify access keys and network rules

For additional support, consult Azure documentation or contact your system administrator.