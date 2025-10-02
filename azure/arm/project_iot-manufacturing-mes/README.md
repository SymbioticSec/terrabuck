# Smart Manufacturing Execution System (MES) - Azure ARM Template

## Overview

This ARM template deploys a complete cloud-based Manufacturing Execution System for automotive parts manufacturing. The system provides real-time data collection from production line sensors, work order tracking, equipment performance monitoring, and dashboards for plant managers.

## Architecture Components

### Core Services
- **IoT Hub**: Ingests telemetry from production sensors, PLCs, and SCADA systems
- **Stream Analytics**: Real-time processing for anomaly detection and KPI calculations  
- **App Service**: MES dashboard web application for production managers
- **SQL Database**: Stores work orders, equipment data, and historical sensor readings
- **Storage Account**: Blob storage for reports, manuals, and archived data
- **Function App**: Serverless functions for ERP integration and notifications

### Network Architecture
- **Virtual Network**: Three-subnet design (public, private, IoT)
- **Network Security Groups**: Subnet-level security controls
- **Private Endpoints**: Secure database connectivity

### Monitoring & Security
- **Application Insights**: Application performance monitoring
- **Log Analytics**: Centralized logging and analytics
- **SQL Threat Detection**: Database security monitoring

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or PowerShell installed
- Resource group created for deployment

## Deployment Instructions

### 1. Clone Repository
```bash
git clone <repository-url>
cd smart-manufacturing-mes
```

### 2. Update Parameters
Edit the `variables.json` file with your specific values:
- `location`: Azure region for deployment
- `environmentName`: Environment identifier (dev/test/prod)
- `sqlAdminUsername`: SQL Server administrator username
- `sqlAdminPassword`: Strong password for SQL Server

### 3. Deploy Template

#### Using Azure CLI:
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.json \
  --parameters @variables.json
```

#### Using PowerShell:
```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "<your-resource-group>" `
  -TemplateFile "main.json" `
  -TemplateParameterFile "variables.json"
```

### 4. Post-Deployment Configuration

1. **Configure IoT Devices**: Register production line sensors with IoT Hub
2. **Database Schema**: Deploy MES database schema to SQL Database
3. **Stream Analytics Query**: Configure real-time processing queries
4. **Web Application**: Deploy MES dashboard application code
5. **Function Apps**: Deploy ERP integration and notification functions

## Resource Naming Convention

Resources follow the pattern: `smart-manufacturing-mes-{environment}-{resource-type}-{identifier}`

Examples:
- IoT Hub: `smart-manufacturing-mes-prod-iothub-001`
- Web App: `smart-manufacturing-mes-prod-webapp-001`
- SQL Server: `smart-manufacturing-mes-prod-sqlserver-001`

## Security Considerations

- SQL Database configured with firewall rules
- Storage Account with network access controls
- App Service with TLS configuration
- Network Security Groups for subnet protection
- Application Insights for monitoring

## Monitoring and Alerting

- Application Insights tracks web application performance
- Log Analytics workspace collects system logs
- SQL Database threat detection monitors for security events
- Stream Analytics provides real-time alerting capabilities

## Estimated Costs

Monthly cost estimates (East US region):
- IoT Hub (S1): ~$25
- Stream Analytics (1 SU): ~$80
- App Service (S1): ~$73
- SQL Database (S0): ~$15
- Storage Account: ~$5
- Function App: ~$10

**Total estimated monthly cost: ~$208**

## Support and Troubleshooting

### Common Issues

1. **SQL Connection Failures**: Verify firewall rules and credentials
2. **IoT Device Connectivity**: Check device connection strings and certificates
3. **Stream Analytics Errors**: Validate input/output configurations
4. **Web App Performance**: Monitor Application Insights for bottlenecks

### Monitoring Dashboards

Access monitoring through:
- Azure Portal > Application Insights
- Log Analytics workspace queries
- SQL Database monitoring blade

## Compliance and Governance

This template includes:
- Resource tagging for cost management
- Security configurations for data protection
- Audit logging capabilities
- Backup and retention policies

## Next Steps

1. Configure production line sensor integration
2. Set up ERP system connectivity
3. Customize dashboards for plant managers
4. Implement predictive maintenance workflows
5. Configure automated alerting rules

For additional support, refer to Azure documentation or contact your system administrator.