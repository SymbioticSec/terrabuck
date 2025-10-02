# Enterprise Video Streaming and Training Platform

This ARM template deploys a comprehensive video streaming platform for corporate training and communications on Microsoft Azure.

## Architecture Overview

The platform consists of the following components:

- **Video Storage**: Azure Storage Account for raw videos, transcoded outputs, and thumbnails
- **Media Services**: Azure Media Services for video transcoding and adaptive streaming
- **API Backend**: App Service hosting REST API for video management and analytics
- **Video Database**: Azure SQL Database for metadata, user profiles, and analytics
- **Web Frontend**: App Service hosting React-based video player interface
- **CDN Endpoint**: Azure CDN for global content delivery and caching

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or PowerShell installed
- Resource group created for deployment

## Deployment Instructions

### Using Azure CLI

1. Clone this repository and navigate to the template directory
2. Create a resource group:
   ```bash
   az group create --name rg-video-streaming-prod --location "East US"
   ```

3. Deploy the template:
   ```bash
   az deployment group create \
     --resource-group rg-video-streaming-prod \
     --template-file main.json \
     --parameters @variables.json
   ```

### Using PowerShell

1. Create a resource group:
   ```powershell
   New-AzResourceGroup -Name "rg-video-streaming-prod" -Location "East US"
   ```

2. Deploy the template:
   ```powershell
   New-AzResourceGroupDeployment `
     -ResourceGroupName "rg-video-streaming-prod" `
     -TemplateFile "main.json" `
     -TemplateParameterFile "variables.json"
   ```

## Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| projectName | Base name for all resources | enterprise-video-streaming-and-training-platform |
| location | Azure region for deployment | Resource group location |
| environment | Environment name (dev/staging/prod) | prod |
| sqlAdminUsername | SQL Server admin username | videoadmin |
| sqlAdminPassword | SQL Server admin password | (required) |
| appServicePlanSku | App Service Plan SKU | S2 |
| storageAccountType | Storage replication type | Standard_LRS |
| cdnSkuName | CDN profile SKU | Standard_Microsoft |

## Post-Deployment Configuration

1. **Media Services Setup**:
   - Configure streaming endpoints
   - Set up content key policies for DRM protection
   - Create transforms for video encoding presets

2. **Database Schema**:
   - Run database migration scripts to create tables
   - Set up user authentication and authorization tables
   - Configure analytics and reporting schemas

3. **Application Deployment**:
   - Deploy API backend code to the App Service
   - Deploy React frontend application
   - Configure environment variables and connection strings

4. **CDN Configuration**:
   - Set up custom domain and SSL certificates
   - Configure caching rules and compression
   - Enable geo-filtering if required

## Security Considerations

- All App Services use managed identities for authentication
- SQL Database includes firewall rules and threat detection
- Storage Account has blob encryption enabled
- CDN enforces HTTPS for content delivery
- Network security groups control traffic between subnets

## Monitoring and Logging

- Application Insights for application monitoring
- Azure Monitor for infrastructure metrics
- SQL Database auditing and threat detection
- Storage Account logging for access patterns

## Scaling Considerations

- App Service Plan can be scaled up/out based on demand
- SQL Database supports elastic pools for cost optimization
- CDN provides global edge caching for performance
- Media Services scales automatically for encoding workloads

## Cost Optimization

- Storage lifecycle policies for automated blob tiering
- CDN caching reduces origin server load
- SQL Database can use reserved capacity pricing
- App Services support auto-scaling to optimize costs

## Support and Troubleshooting

For issues with deployment or configuration:

1. Check Azure Activity Log for deployment errors
2. Review App Service logs for application issues
3. Monitor SQL Database performance metrics
4. Verify CDN endpoint configuration and caching rules

## License

This template is provided under the MIT License. See LICENSE file for details.