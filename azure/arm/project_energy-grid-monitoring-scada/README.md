# Smart Grid SCADA Monitoring Platform

## Overview

This ARM template deploys a comprehensive energy grid monitoring system that collects real-time data from SCADA devices across power substations, processes telemetry data for anomaly detection, and provides operational dashboards for grid operators.

## Architecture Components

### Core Services
- **IoT Hub**: Secure ingestion of SCADA telemetry data from field devices
- **Stream Analytics**: Real-time processing for anomaly detection and threshold monitoring
- **Time Series Insights**: Long-term storage and analysis of historical grid performance data
- **SQL Database**: Stores grid topology, device configurations, and operational metadata
- **App Service**: Web-based SCADA HMI for grid operators with real-time visualization
- **Logic Apps**: Automated alerting system for critical grid events

### Supporting Infrastructure
- **Virtual Network**: Hub-spoke architecture with security zone segmentation
- **Network Security Groups**: Traffic control between OT and IT zones
- **Key Vault**: Centralized secrets management
- **Log Analytics**: Centralized logging and monitoring
- **Application Insights**: Application performance monitoring
- **Private Endpoints**: Secure connectivity for database access

## Deployment Instructions

### Prerequisites
- Azure CLI or PowerShell with Azure modules
- Contributor access to target Azure subscription
- Resource group created for deployment

### Quick Deployment

1. **Clone or download the template files**
   ```bash
   # Ensure you have main.json and variables.json in the same directory
   ```

2. **Deploy using Azure CLI**
   ```bash
   az deployment group create \
     --resource-group your-resource-group \
     --template-file main.json \
     --parameters @variables.json
   ```

3. **Deploy using PowerShell**
   ```powershell
   New-AzResourceGroupDeployment `
     -ResourceGroupName "your-resource-group" `
     -TemplateFile "main.json" `
     -TemplateParameterFile "variables.json"
   ```

### Custom Deployment

1. **Modify variables.json for your environment**
   ```json
   {
     "parameters": {
       "location": {
         "value": "your-preferred-region"
       },
       "environmentName": {
         "value": "dev|test|prod"
       },
       "sqlAdminPassword": {
         "value": "your-secure-password"
       }
     }
   }
   ```

2. **Deploy with custom parameters**
   ```bash
   az deployment group create \
     --resource-group your-resource-group \
     --template-file main.json \
     --parameters location="West US 2" environmentName="test"
   ```

## Post-Deployment Configuration

### 1. Configure SCADA Device Connections
- Retrieve IoT Hub connection string from deployment outputs
- Configure field devices with device-specific connection strings
- Set up device certificates for secure authentication

### 2. Set Up Stream Analytics Queries
- Access Stream Analytics job in Azure portal
- Configure queries for anomaly detection and threshold monitoring
- Set up outputs to Time Series Insights and alerting systems

### 3. Configure Operator Dashboard
- Access the dashboard URL from deployment outputs
- Set up authentication and role-based access control
- Configure real-time data visualization components

### 4. Set Up Alerting Rules
- Configure Logic Apps workflows for critical alerts
- Set up notification channels (email, SMS, teams)
- Test alert escalation procedures

## Security Considerations

### Network Security
- OT network isolation with dedicated subnets
- Network security groups enforce traffic segmentation
- Private endpoints for database connectivity

### Data Protection
- Encryption in transit and at rest
- Key Vault for secrets management
- SQL