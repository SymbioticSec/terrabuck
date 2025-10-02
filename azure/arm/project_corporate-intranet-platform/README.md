# Corporate Intranet Platform - ARM Template Deployment

## Overview

This ARM template deploys a comprehensive corporate intranet platform with document management capabilities on Microsoft Azure. The solution includes web applications, serverless APIs, secure storage, search functionality, and integrated security features.

## Architecture Components

- **Web Application**: Main intranet portal hosted on Azure App Service
- **Document API**: Serverless functions for document operations
- **SQL Database**: Stores user profiles, metadata, and audit logs
- **Storage Account**: Secure blob storage for documents and attachments
- **Search Service**: Full-text search across documents and content
- **Application Gateway**: Load balancer with WAF protection
- **Virtual Network**: Segmented network with public, private, and data subnets

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

2. **Login to Azure**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

3. **Create a resource group (if not exists)**
   ```bash
   az group create --name "rg-corporate-intranet" --location "East US"
   ```

4. **Deploy the template**
   ```bash
   az deployment group create \
     --resource-group "rg-corporate-intranet" \
     --template-file main.json \
     --parameters @variables.json
   ```

### Using Azure PowerShell

1. **Connect to Azure**
   ```powershell
   Connect-AzAccount
   Set-AzContext -SubscriptionId "your-subscription-id"
   ```

2. **Create resource group**
   ```powershell
   New-AzResourceGroup -Name "rg-corporate-intranet" -Location "East US"
   ```

3. **Deploy template**
   ```powershell
   New-AzResourceGroupDeployment `
     -ResourceGroupName "rg-corporate-intranet" `
     -TemplateFile "main.json" `
     -TemplateParameterFile "variables.json"
   ```

## Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| location | Azure region for deployment | Resource group location |
| environmentName | Environment identifier | prod |
| sqlAdminUsername | SQL Server admin username | sqladmin |
| sqlAdminPassword | SQL Server admin password | (secure parameter) |
| appServicePlanSku | App Service Plan pricing tier | S1 |
| storageAccountType | Storage replication type | Standard_LRS |

## Post-Deployment Configuration

### 1. Configure Active Directory Integration

```bash
# Set up Azure AD authentication for the web app
az webapp auth update \
  --resource-group "rg-corporate-intranet" \
  --name "corporate-intranet-prod-webapp" \
  --enabled true \
  --action LoginWithAzureActiveDirectory
```

### 2. Configure SQL Database Connection

Update the web app connection strings:

```bash
az webapp config connection-string set \
  --resource-group "rg-corporate-intranet" \
  --name "corporate-intranet-prod-webapp" \
  --connection-string-type SQLAzure \
  --settings DefaultConnection="Server=tcp:corporate-intranet-prod-sqlserver.database.windows.net,1433;Database=corporate-intranet-prod-database;User ID=sqladmin;Password=P@ssw0rd123!;Encrypt=true;Connection Timeout=30;"
```

### 3. Configure Storage Account Access

Set up managed identity for secure storage access:

```bash
# Enable managed identity for web app
az webapp identity assign \
  --resource-group "rg-corporate-intranet" \
  --name "corporate-intranet-prod-webapp"

# Grant storage access to the managed identity
az role assignment create \
  --assignee [managed-identity-principal-id] \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/[subscription-id]/resourceGroups/rg-corporate-intranet/providers/Microsoft.Storage/storageAccounts/corporateintranetprodstorage"
```

## Security Considerations

- SQL Server firewall rules need to be configured for database access
- Storage account access keys should be rotated regularly
- Application Gateway SSL certificates need to be configured for HTTPS
- Network security groups may need adjustment based on requirements
- Enable diagnostic logging for all services

## Monitoring and Maintenance

- Log Analytics workspace is included for centralized logging
- Configure alerts for critical metrics
- Set up backup policies for SQL Database
- Monitor Application Gateway WAF logs
- Review security recommendations in Azure Security Center

## Troubleshooting

### Common Issues

1. **Deployment Fails**: Check resource naming conflicts and subscription limits
2. **SQL Connection Issues**: Verify firewall rules and connection strings
3. **Storage Access Problems**: Confirm managed identity permissions
4. **Application Gateway Health**: Check backend pool health status

### Useful Commands

```bash
# Check deployment status
az deployment group show --resource-group "rg-corporate-intranet" --name "main"

# View resource group resources
az resource list --resource-group "rg-corporate-intranet" --output table

# Check web app logs
az webapp log tail --resource-group "rg-corporate-intranet" --name "corporate-intranet-prod-webapp"
```

## Cost Optimization

- Consider using Azure Reserved Instances for predictable workloads
- Implement auto-scaling for App Service Plans
- Use lifecycle management for storage accounts
- Monitor usage with Azure Cost Management

## Support

For issues with this deployment:
1. Check Azure Activity Log for deployment errors
2. Review resource-specific diagnostic logs
3. Consult Azure documentation for service-specific guidance
4. Contact Azure support for platform issues

## License

This template is provided as-is for educational and development purposes.