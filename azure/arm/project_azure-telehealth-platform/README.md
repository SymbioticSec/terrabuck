# Telehealth Video Consultation Platform - Azure ARM Template

This ARM template deploys a complete HIPAA-compliant telehealth platform on Azure, enabling secure video consultations between healthcare providers and patients.

## Architecture Overview

The platform implements a microservices architecture with the following components:

- **Application Gateway**: SSL termination, WAF protection, and load balancing
- **App Service**: React-based patient portal for appointment booking and consultations
- **Azure Communication Services**: Real-time video/audio streaming and chat
- **Container Instances**: Microservices API for appointment and patient record management
- **SQL Database**: Encrypted storage for patient records and appointment data
- **Storage Account**: Immutable storage for audit logs and consultation recordings

## Network Architecture

- **Public Subnet**: Application Gateway with public IP
- **Private Subnet**: App Services and Container Instances
- **Data Subnet**: SQL Database with private endpoints

## Prerequisites

- Azure subscription with appropriate permissions
- Resource group created for deployment
- Azure CLI or PowerShell installed

## Deployment Instructions

### Using Azure CLI

1. Clone this repository:
```bash
git clone <repository-url>
cd telehealth-platform-arm
```

2. Create a resource group:
```bash
az group create --name telehealth-rg --location "East US"
```

3. Deploy the template:
```bash
az deployment group create \
  --resource-group telehealth-rg \
  --template-file main.json \
  --parameters @variables.json
```

### Using Azure PowerShell

1. Create a resource group:
```powershell
New-AzResourceGroup -Name "telehealth-rg" -Location "East US"
```

2. Deploy the template:
```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "telehealth-rg" `
  -TemplateFile "main.json" `
  -TemplateParameterFile "variables.json"
```

### Using Azure Portal

1. Navigate to Azure Portal
2. Search for "Deploy a custom template"
3. Upload the main.json file
4. Fill in the required parameters
5. Click "Review + create" and then "Create"

## Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| location | Azure region for deployment | Resource group location |
| environmentName | Environment identifier (dev/test/prod) | prod |
| sqlAdminUsername | SQL Server administrator username | sqladmin |
| sqlAdminPassword | SQL Server administrator password | (required) |
| communicationServiceName | Azure Communication Services name | Auto-generated |

## Post-Deployment Configuration

### 1. Configure Application Gateway Backend Pool

After deployment, configure the Application Gateway backend pool to point to your App Service:

```bash
az network application-gateway address-pool update \
  --gateway-name telehealth-video-consultation-platform-prod-appgw \
  --resource-group telehealth-rg \
  --name appGatewayBackendPool \
  --servers <your-app-service-fqdn>
```

### 2. Configure SSL Certificate

Upload your SSL certificate to the Application Gateway:

```bash
az network application-gateway ssl-cert create \
  --gateway-name telehealth-video-consultation-platform-prod-appgw \
  --resource-group telehealth-rg \
  --name ssl-cert \
  --cert-file certificate.pfx \
  --cert-password <certificate-password>
```

### 3. Database Schema Setup

Connect to the SQL Database and run your schema creation scripts:

```sql
-- Example patient table
CREATE TABLE Patients (
    PatientId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    CreatedDate DATETIME2 DEFAULT GETUTCDATE()
);
```

### 4. Configure Azure Communication Services

Retrieve the connection string for Azure Communication Services:

```bash
az communication list-key \
  --name telehealth-video-consultation-platform-prod-acs \
  --resource-group telehealth-rg
```

## Security Features

- **WAF Protection**: OWASP rule set enabled on Application Gateway
- **Network Isolation**: Private subnets for backend services
- **Database Encryption**: Transparent Data Encryption enabled
- **HTTPS Enforcement**: SSL/TLS termination at Application Gateway
- **Private Endpoints**: Secure database connectivity
- **Audit Logging**: Comprehensive logging to storage account

## Monitoring and Compliance

### Application Insights

Enable Application Insights for monitoring:

```bash
az monitor app-insights component create \
  --app telehealth-insights \
  --location "East US" \
  --resource-group telehealth-rg \
  --application-type web
```

### Log Analytics

Configure Log Analytics workspace for centralized logging:

```bash
az monitor log-analytics workspace create \
  --resource-group telehealth-rg \
  --workspace-name telehealth-logs \
  --location "East US"
```

## Scaling Considerations

- **App Service Plan**: Can be scaled up/out based on demand
- **SQL Database**: Configure auto-scaling or upgrade to higher tiers
- **Container Instances**: Implement Azure Container Apps for better scaling
- **Storage Account**: Monitor usage and configure lifecycle policies

## Backup and Disaster Recovery

- **SQL Database**: Automated backups with point-in-time restore
- **Storage Account**: Geo-redundant storage for audit logs
- **Configuration**: Export ARM templates for infrastructure recovery

## Cost Optimization

- **App Service**: Use reserved instances for production
- **SQL Database**: Consider serverless tier for development
- **Storage**: Implement lifecycle policies for old audit logs
- **Monitoring**: Set up cost alerts and budgets

## Troubleshooting

### Common Issues

1. **Deployment Failures**: Check resource naming constraints and quotas
2. **Network Connectivity**: Verify NSG rules and subnet configurations
3. **Database Access**: Ensure firewall rules allow necessary connections
4. **SSL Issues**: Verify certificate installation and binding

### Diagnostic Commands

```bash