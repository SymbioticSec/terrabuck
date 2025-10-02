# Smart Manufacturing IoT Monitoring Platform

This Terraform configuration deploys a comprehensive IoT platform for monitoring manufacturing equipment across multiple factory floors. The system collects real-time sensor data from industrial equipment, processes it for anomaly detection, stores historical data for analytics, and provides a dashboard for plant managers.

## Architecture Overview

The platform implements an event-driven IoT architecture with the following components:

- **IoT Hub**: Ingests telemetry data from manufacturing equipment sensors via MQTT/HTTPS protocols
- **Stream Analytics**: Real-time processing of sensor data for anomaly detection and threshold monitoring
- **Function App**: Serverless functions to send immediate alerts for equipment failures and maintenance needs
- **Data Explorer**: Stores historical sensor data optimized for time-series queries and analytics
- **Web App**: Dashboard providing real-time dashboards and historical analytics for plant managers
- **Blob Storage**: Stores raw sensor data archives, maintenance reports, and equipment documentation

## Network Architecture

The infrastructure is deployed across three subnets:
- **Public Subnet**: Application Gateway for external access
- **Private Subnet**: App Services and Function Apps
- **Data Subnet**: Databases with restricted access

## Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0 installed
- Appropriate Azure permissions to create resources

## Deployment Instructions

1. **Clone and Navigate**
   ```bash
   git clone <repository-url>
   cd smart-manufacturing-iot-platform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review and Customize Variables**
   ```bash
   # Edit terraform.tfvars or use -var flags
   cp terraform.tfvars.example terraform.tfvars
   ```

4. **Plan Deployment**
   ```bash
   terraform plan
   ```

5. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

## Configuration

### Required Variables

- `resource_group_name`: Name of the resource group (default: "rg-smart-manufacturing-iot-monitoring-platform")
- `location`: Azure region for deployment (default: "East US")
- `environment`: Environment tag (default: "production")
- `storage_account_name`: Storage account name for blob storage
- `function_storage_account_name`: Storage account name for function app
- `kusto_cluster_name`: Azure Data Explorer cluster name

### Optional Customization

You can customize the deployment by modifying variables in `terraform.tfvars`:

```hcl
resource_group_name = "my-custom-rg"
location           = "West US 2"
environment        = "staging"
owner             = "my-team"
```

## Post-Deployment Configuration

1. **Configure IoT Devices**
   - Use the IoT Hub connection string from outputs to register devices
   - Configure device authentication certificates

2. **Set Up Stream Analytics Queries**
   - Define input from IoT Hub
   - Configure output to Data Explorer and Function App
   - Create queries for anomaly detection

3. **Deploy Function App Code**
   - Deploy alert processing functions
   - Configure notification endpoints (email, SMS, etc.)

4. **Configure Dashboard Application**
   - Deploy web application code
   - Configure connection to Data Explorer
   - Set up authentication and authorization

## Monitoring and Maintenance

- Monitor IoT Hub metrics for device connectivity
- Review Stream Analytics job performance
- Check Function App execution logs
- Monitor Data Explorer query performance
- Review storage account usage and costs

## Security Considerations

This deployment includes several security features:
- Network segmentation with subnets
- Network Security Groups with traffic rules
- Storage account access controls
- Application Gateway for secure external access

## Scaling

The platform can be scaled by:
- Increasing IoT Hub units for more devices
- Scaling Stream Analytics streaming units
- Upgrading App Service plans
- Adding Data Explorer cluster capacity

## Cost Optimization

- Monitor resource usage regularly
- Consider reserved instances for predictable workloads
- Implement lifecycle policies for blob storage
- Review and optimize Stream Analytics queries

## Troubleshooting

Common issues and solutions:

1. **IoT Hub Connection Issues**
   - Verify device connection strings
   - Check network connectivity
   - Review device authentication

2. **Stream Analytics Job Failures**
   - Check input/output configurations
   - Review query syntax
   - Monitor streaming units

3. **Function App Errors**
   - Check application logs
   - Verify storage account connectivity
   - Review function code

## Support

For support and questions:
- Review Azure documentation
- Check Terraform Azure provider documentation
- Contact the manufacturing operations team

## License

This project is licensed under the MIT License - see the LICENSE file for details.