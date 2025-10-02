# Corporate Media Streaming Platform - Azure Infrastructure

This Terraform configuration deploys a complete corporate media streaming platform on Microsoft Azure, designed for internal corporate communications, training videos, and executive broadcasts.

## Architecture Overview

The platform implements a microservices architecture with the following components:

- **Media Storage**: Azure Storage Account for raw and transcoded video files
- **Media Services**: Azure Media Services for video transcoding and streaming
- **Web Application**: Frontend web app for video upload and streaming interface
- **API Backend**: REST API for authentication, metadata, and analytics
- **Application Database**: Azure SQL Database for user profiles and video metadata
- **CDN Distribution**: Azure CDN for optimized global content delivery

## Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0 installed
- Azure subscription with appropriate permissions
- PowerShell or Bash terminal

## Deployment Instructions

### 1. Clone and Navigate

```bash
git clone <repository-url>
cd corporate-media-streaming-platform
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Configure Variables

Create a `terraform.tfvars` file:

```hcl
resource_group_name = "rg-corporate-media-streaming-prod"
location           = "East US"
environment        = "production"
sql_admin_username = "sqladmin"
sql_admin_password = "YourSecurePassword123!"
```

### 4. Plan Deployment

```bash
terraform plan
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

When prompted, type `yes` to confirm deployment.

### 6. Verify Deployment

After successful deployment, verify the resources in the Azure Portal:

- Resource Group: `rg-corporate-media-streaming-prod`
- Storage Account: Check blob containers are created
- Media Services: Verify streaming endpoints
- App Services: Check web app and API are running
- SQL Database: Verify database is accessible
- CDN: Confirm endpoint is active

## Post-Deployment Configuration

### 1. Database Setup

Connect to the SQL database and run initialization scripts:

```sql
-- Create tables for user profiles, video metadata, and analytics
-- Configure authentication and authorization
```

### 2. Media Services Configuration

- Configure streaming policies
- Set up content protection keys
- Configure encoding presets

### 3. Application Deployment

Deploy application code to the App Services:

```bash
# Deploy web application
az webapp deployment source config-zip --resource-group <rg-name> --name <webapp-name> --src webapp.zip

# Deploy API backend
az webapp deployment source config-zip --resource-group <rg-name> --name <api-name> --src api.zip
```

### 4. CDN Configuration

- Configure caching rules
- Set up custom domains if needed
- Configure SSL certificates

## Security Considerations

This deployment includes several security features:

- Virtual network isolation with subnets
- Network security groups with controlled access
- Storage account with blob encryption
- SQL database with TDE encryption
- App Services with managed identities
- CDN with token authentication

## Monitoring and Maintenance

### Application Insights

Configure Application Insights for monitoring:

- Web application performance
- API response times
- Database query performance
- CDN cache hit rates

### Backup Strategy

- SQL Database: Automated backups enabled
- Storage Account: Geo-redundant replication
- Media Services: Content backup to secondary storage

### Scaling Considerations

- App Service Plan: Can scale up/out based on demand
- SQL Database: Elastic pool for cost optimization
- CDN: Global distribution for performance
- Storage: Automatic scaling with usage

## Cost Optimization

- Use Azure Cost Management for monitoring
- Implement lifecycle policies for storage
- Configure auto-scaling for App Services
- Monitor CDN usage and optimize caching

## Troubleshooting

### Common Issues

1. **Storage Access Issues**
   - Verify network security group rules
   - Check storage account firewall settings

2. **Database Connection Problems**
   - Confirm SQL firewall rules
   - Verify connection strings in app settings

3. **Media Services Streaming Issues**
   - Check streaming endpoint status
   - Verify content protection policies

4. **CDN Performance Issues**
   - Review caching rules
   - Check origin server response times

### Support Resources

- Azure Documentation: https://docs.microsoft.com/azure/
- Terraform Azure Provider: https://registry.terraform.io/providers/hashicorp/azurerm/
- Azure Support: Create support ticket in Azure Portal

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources and data. Ensure you have backups before proceeding.

## License

This infrastructure code is provided under the MIT License. See LICENSE file for details.