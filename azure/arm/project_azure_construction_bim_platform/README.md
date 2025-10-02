# Construction BIM Collaboration Platform - Azure ARM Template

This ARM template deploys a comprehensive Building Information Modeling (BIM) collaboration platform on Azure, designed for construction companies to manage large CAD files, enable real-time collaboration, and track project progress.

## Architecture Overview

The platform implements a multi-tier architecture with the following components:

- **Web Frontend**: React-based web application hosted on Azure App Service
- **API Backend**: REST API for user management and project operations on Azure App Service
- **File Storage**: Azure Storage Account with blob containers for BIM files, CAD drawings, and documents
- **Project Database**: Azure SQL Database for metadata, user roles, and collaboration history
- **Cache Layer**: Azure Redis Cache for performance optimization
- **Load Balancer**: Azure Application Gateway with WAF protection

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or PowerShell installed
- Resource group created for deployment

## Deployment Instructions

### Option 1: Azure CLI

```bash
# Create resource group
az group create --name rg-construction-bim-platform --location "East US"

# Deploy the template
az deployment group create \
  --resource-group rg-construction-bim-platform \
  --template-file main.json \
  --parameters @variables.json
```

### Option 2: Azure PowerShell

```powershell
# Create resource group
New-AzResourceGroup -Name "rg-construction-bim-platform" -Location "East US"

# Deploy the template
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-construction-bim-platform" `
  -TemplateFile "main.json" `
  -TemplateParameterFile "variables.json"
```

### Option 3: Azure Portal

1. Navigate to Azure Portal
2. Search for "Deploy a custom template"
3. Upload the main.json file
4. Fill in the required parameters or upload variables.json
5. Click "Review + create" and then "Create"

## Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| location | Azure region for deployment | Resource group location |
| environmentName | Environment identifier | prod |
| sqlAdminUsername | SQL Server admin username | bimsqladmin |
| sqlAdminPassword | SQL Server admin password | (required) |
| appServicePlanSku | App Service Plan pricing tier | S1 |
| storageAccountType | Storage replication type | Standard_LRS |
| redisCacheSku | Redis Cache pricing tier | Basic |
| applicationGatewayTier | Application Gateway tier | Standard_v2 |

## Post-Deployment Configuration

### 1. Configure App Service Authentication

```bash
# Enable authentication for web app
az webapp auth update \
  --resource-group rg-construction-bim-platform \
  --name construction-bim-collaboration-platform-web-prod \
  --enabled true \
  --action LoginWithAzureActiveDirectory
```

### 2. Set up SSL Certificates

Upload SSL certificates to Application Gateway for HTTPS termination.

### 3. Configure Database Schema

Connect to the SQL Database and run your schema creation scripts:

```sql
-- Example table creation
CREATE TABLE Projects (
    ProjectId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    ProjectName NVARCHAR(255) NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETUTCDATE(),
    Status NVARCHAR(50) DEFAULT 'Active'
);
```

### 4. Set Application Settings

Configure connection strings and app settings for both web and API applications:

```bash
# Set connection string for API app
az webapp config connection-string set \
  --resource-group rg-construction-bim-platform \
  --name construction-bim-collaboration-platform-api-prod \
  --connection-string-type SQLAzure \
  --settings DefaultConnection="Server=tcp:construction-bim-collaboration-platform-sql-prod.database.windows.net,1433;Database=construction-bim-collaboration-platform-db-prod;User ID=bimsqladmin;Password=YourPassword;Encrypt=true;"
```

## Network Security

The template creates a Virtual Network with three subnets:
- **Public Subnet**: Application Gateway (10.0.1.0/24)
- **Private Subnet**: App Services (10.0.2.0/24)
- **Data Subnet**: SQL Database and Redis Cache (10.0.3.0/24)

Network Security Groups are configured to control traffic flow between tiers.

## Storage Configuration

Three blob containers are created:
- **bim-files**: For large BIM model files
- **cad-drawings**: For CAD drawings and technical documents
- **project-documents**: For project documentation and reports

## Monitoring and Logging

The template includes Log Analytics workspace for centralized logging. Configure diagnostic settings for all resources to send logs to this workspace.

## Scaling Considerations

- App Service Plan can be scaled up/out based on demand
- SQL Database supports automatic scaling
- Redis Cache can be upgraded to higher tiers
- Application Gateway supports auto-scaling

## Security Best Practices

1. Enable Azure AD authentication for App Services
2. Configure SSL/TLS certificates
3. Implement proper RBAC roles
4. Enable diagnostic logging
5. Regular security assessments
6. Keep all services updated

## Troubleshooting

### Common Issues

1. **Deployment Failures**: Check resource naming conflicts and quota limits
2. **Connectivity Issues**: Verify NSG rules and subnet configurations
3. **Authentication Problems**: Ensure Azure AD is properly configured
4. **Performance Issues**: Monitor App Service metrics and scale accordingly

### Useful Commands

```bash
# Check deployment status
az deployment group show --resource-group rg-construction-bim-platform --name main

# View resource group resources
az resource list --resource-group rg-construction-bim-platform --output table

# Get connection strings
az sql db show-connection-string --server construction-bim-collaboration-platform-sql-prod --name construction-bim-collaboration-platform-db-prod --client ado.net
```

## Cost Optimization

- Use Azure Cost Management to monitor spending
- Consider reserved instances for predictable workloads
- Implement auto-shutdown for development environments
- Regular review of resource utilization

## Support and Maintenance

- Regular backups are automatically configured for SQL Database
- Monitor resource health through Azure Monitor
- Set up alerts for critical metrics
- Plan for regular security updates

For additional support, refer to Azure documentation or contact your system administrator.