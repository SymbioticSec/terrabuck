# Fleet Management Platform with GPS Tracking

This ARM template deploys a comprehensive fleet management system for logistics companies managing 500+ delivery vehicles. The platform provides real-time GPS tracking, route optimization, driver behavior monitoring, and maintenance scheduling.

## Architecture Overview

The solution implements an event-driven microservices architecture with the following components:

- **Web Dashboard** (Azure App Service): Fleet management interface for dispatchers and managers
- **Telemetry Processor** (Azure Functions): Serverless processing of real-time GPS and vehicle data
- **Fleet Database** (Azure SQL Database): Primary storage for vehicle, driver, and operational data
- **Telemetry Storage** (Azure Storage Account): Time-series storage for GPS coordinates and analytics
- **Message Queue** (Azure Service Bus): High-volume message processing for telemetry ingestion
- **API Gateway** (Azure API Management): Secure endpoints for mobile apps and third-party integrations

## Network Architecture

- **Public Subnet**: App Service and API Management
- **Private Subnet**: Azure Functions and Service Bus
- **Data Subnet**: SQL Database with private endpoints

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or PowerShell installed
- Resource group created for deployment

## Deployment Instructions

### Option 1: Azure CLI

```bash
# Create resource group
az group create --name fleet-management-rg --location "East US"

# Deploy template
az deployment group create \
  --resource-group fleet-management-rg \
  --template-file main.json \
  --parameters @variables.json
```

### Option 2: Azure PowerShell

```powershell
# Create resource group
New-AzResourceGroup -Name "fleet-management-rg" -Location "East US"

# Deploy template
New-AzResourceGroupDeployment `
  -ResourceGroupName "fleet-management-rg" `
  -TemplateFile "main.json" `
  -TemplateParameterFile "variables.json"
```

### Option 3: Azure Portal

1. Navigate to Azure Portal
2. Search for "Deploy a custom template"
3. Upload the main.json file
4. Fill in the required parameters
5. Click "Review + create"

## Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| location | Azure region for deployment | Resource group location |
| environmentName | Environment identifier | prod |
| sqlAdminUsername | SQL Server admin username | fleetadmin |
| sqlAdminPassword | SQL Server admin password | (required) |
| appServicePlanSku | App Service Plan pricing tier | S1 |
| storageAccountType | Storage account replication type | Standard_LRS |

## Post-Deployment Configuration

### 1. Configure Application Settings

Update the web application and function app with necessary connection strings and API keys:

```bash
# Set Service Bus connection string
az webapp config appsettings set \
  --resource-group fleet-management-rg \
  --name fleet-mgmt-prod-functions \
  --settings "ServiceBusConnection=<connection-string>"
```

### 2. Set up API Management Policies

Configure rate limiting, authentication, and CORS policies in API Management.

### 3. Database Schema Setup

Connect to the SQL database and run the schema creation scripts:

```sql
-- Create tables for fleet management
CREATE TABLE Vehicles (
    VehicleId INT PRIMARY KEY IDENTITY,
    VIN VARCHAR(17) UNIQUE NOT NULL,
    LicensePlate VARCHAR(20),
    Make VARCHAR(50),
    Model VARCHAR(50),
    Year INT,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE Drivers (
    DriverId INT PRIMARY KEY IDENTITY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    LicenseNumber VARCHAR(20) UNIQUE,
    PhoneNumber VARCHAR(15),
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE TelemetryData (
    TelemetryId BIGINT PRIMARY KEY IDENTITY,
    VehicleId INT FOREIGN KEY REFERENCES Vehicles(VehicleId),
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    Speed DECIMAL(5,2),
    Timestamp DATETIME2 DEFAULT GETDATE()
);
```

### 4. Configure Monitoring

Set up Application Insights dashboards and alerts for:
- Function execution metrics
- Database performance
- Storage account usage
- API Management request rates

## Security Considerations

- SQL Database uses private endpoints for secure connectivity
- Storage accounts are configured with access policies
- API Management provides authentication and rate limiting
- Key Vault stores sensitive configuration data
- Network Security Groups control traffic flow

## Monitoring and Logging

The solution includes:
- Application Insights for application performance monitoring
- Log Analytics workspace for centralized logging
- Activity log alerts for administrative actions
- Custom metrics for fleet-specific KPIs

## Scaling Considerations

- App Service Plan can be scaled up/out based on demand
- Azure Functions automatically scale based on queue depth
- SQL Database can be scaled to higher service tiers
- Storage accounts support hot/cool tier management

## Cost Optimization

- Use Azure Cost Management to monitor spending
- Implement storage lifecycle policies
- Consider reserved instances for predictable workloads
- Use Azure Advisor recommendations

## Troubleshooting

### Common Issues

1. **Deployment Failures**: Check resource naming conflicts and quota limits
2. **Connectivity Issues**: Verify network security group rules and private endpoints
3. **Authentication Errors**: Ensure proper service principal permissions
4. **Performance Issues**: Monitor Application Insights for bottlenecks

### Support Resources

- Azure Documentation: https://docs.microsoft.com/azure/
- Azure Support: https://azure.microsoft.com/support/
- Community Forums: https://docs.microsoft.com/answers/

## License

This template is provided under the MIT License. See LICENSE file for details.