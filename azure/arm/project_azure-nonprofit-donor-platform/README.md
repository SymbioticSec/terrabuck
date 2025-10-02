# Nonprofit Donor Management and Fundraising Platform

This ARM template deploys a comprehensive donor management platform for nonprofit organizations to handle online donations, donor communications, campaign management, and financial reporting.

## Architecture Overview

The platform implements a multi-tier web application architecture with the following components:

- **Web Frontend**: Azure App Service hosting donor portal and admin dashboard
- **API Backend**: Azure App Service providing RESTful API services
- **Database**: Azure SQL Database storing donor and financial information
- **File Storage**: Azure Storage Account for documents and campaign assets
- **Email Service**: Azure Functions for automated communications
- **CDN**: Azure CDN for global content delivery

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or PowerShell installed
- Resource group created for deployment

## Deployment Instructions

### Using Azure CLI

1. Clone this repository:
```bash
git clone <repository-url>
cd nonprofit-donor-platform
```

2. Create a resource group:
```bash
az group create --name nonprofit-donor-rg --location "East US"
```

3. Deploy the template:
```bash
az deployment group create \
  --resource-group nonprofit-donor-rg \
  --template-file main.json \
  --parameters @variables.json
```

### Using Azure PowerShell

1. Create a resource group:
```powershell
New-AzResourceGroup -Name "nonprofit-donor-rg" -Location "East US"
```

2. Deploy the template:
```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "nonprofit-donor-rg" `
  -TemplateFile "main.json" `
  -TemplateParameterFile "variables.json"
```

## Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| location | Azure region for deployment | Resource group location |
| environmentName | Environment identifier | prod |
| sqlAdminUsername | SQL Server admin username | sqladmin |
| sqlAdminPassword | SQL Server admin password | (required) |
| appServiceSku | App Service Plan SKU | S1 |
| storageAccountType | Storage replication type | Standard_LRS |

## Post-Deployment Configuration

1. **Database Setup**: Connect to the SQL database and run initialization scripts
2. **App Service Configuration**: Configure connection strings and app settings
3. **Storage Setup**: Configure blob containers and access policies
4. **CDN Configuration**: Set up custom domains and SSL certificates
5. **Function App**: Deploy email service functions

## Security Considerations

- Configure Azure Active Directory authentication for App Services
- Set up SSL certificates for custom domains
- Configure firewall rules for SQL Database
- Implement proper access controls for storage accounts
- Enable monitoring and alerting

## Monitoring and Logging

The template includes:
- Application Insights for application monitoring
- Log Analytics workspace for centralized logging
- Activity log retention for audit trails

## Cost Optimization

- Review App Service Plan sizing based on usage
- Configure storage lifecycle policies
- Monitor SQL Database DTU usage
- Set up cost alerts and budgets

## Support and Maintenance

- Regular security updates for all services
- Database backup verification
- Performance monitoring and optimization
- Compliance reporting for nonprofit regulations

## Troubleshooting

Common issues and solutions:

1. **Deployment Failures**: Check resource naming conflicts and quota limits
2. **Database Connection**: Verify firewall rules and connection strings
3. **Storage Access**: Check access keys and container permissions
4. **CDN Issues**: Verify origin configuration and SSL settings

For additional support, refer to Azure documentation or contact your system administrator.