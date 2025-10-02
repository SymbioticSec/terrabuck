# Smart Grid SCADA Monitoring Platform

This Terraform configuration deploys a comprehensive SCADA monitoring platform for smart grid operations on Microsoft Azure. The system provides real-time telemetry ingestion, processing, and visualization for power grid infrastructure.

## Architecture Overview

The platform implements an event-driven IoT architecture with the following components:

- **IoT Hub**: Secure ingestion of SCADA telemetry from 10,000+ field devices
- **Stream Analytics**: Real-time processing for anomaly detection and alerting
- **Data Explorer**: Time-series database for historical analysis and trending
- **Function App**: Serverless alert processing and notification routing
- **Web App**: Operator dashboard for grid visualization and control
- **Storage Account**: Audit logs and compliance data retention

## Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0
- Appropriate Azure permissions for resource creation
- Valid Azure subscription

## Deployment Instructions

1. **Clone and Initialize**
   ```bash
   git clone <repository-url>
   cd smart-grid-scada-monitoring
   terraform init
   ```

2. **Configure Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Plan Deployment**
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

4. **Deploy Infrastructure**
   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

## Configuration

### Required Variables

- `location`: Azure region (default: "East US")
- `environment`: Environment tag (default: "production")
- `security_contact_email`: Security notifications email

### Optional Variables

- `iot_device_count`: Expected SCADA device count (default: 10000)
- `retention_days`: Data retention period (default: 2555)
- `allowed_ip_ranges`: Permitted IP ranges for access

## Post-Deployment Configuration

1. **Configure IoT Devices**
   - Use the IoT Hub connection string from outputs
   - Register SCADA devices with appropriate certificates
   - Configure device-to-cloud messaging

2. **Set Up Stream Analytics**
   - Configure input from IoT Hub
   - Set up output to Data Explorer
   - Start the streaming job

3. **Initialize Data Explorer**
   - Create tables for telemetry data
   - Set up data ingestion mappings
   - Configure retention policies

4. **Deploy Application Code**
   - Deploy dashboard application to Web App
   - Deploy alert processing functions
   - Configure application settings

## Security Considerations

This deployment implements security controls for critical infrastructure:

- Network isolation with dedicated VNet
- Managed identities for service authentication
- Key Vault for secrets management
- Network security groups for traffic control
- Activity logging and monitoring

## Monitoring and Alerting

The platform includes comprehensive monitoring:

- Azure Monitor integration
- Security Center notifications
- Custom alerting through Function Apps
- Audit trail in storage accounts

## Compliance

The system supports regulatory compliance through:

- Immutable audit logging
- Data retention policies
- Access control and authentication
- Network segmentation

## Troubleshooting

Common issues and solutions:

1. **IoT Hub Connection Issues**
   - Verify device certificates
   - Check network connectivity
   - Validate connection strings

2. **Stream Analytics Failures**
   - Review input/output configurations
   - Check query syntax
   - Monitor streaming units

3. **Dashboard Access Problems**
   - Verify App Service configuration
   - Check authentication settings
   - Review network security groups

## Support

For technical support and issues:
- Email: scada-support@gridoperations.com
- Documentation: [Internal Wiki Link]
- Emergency: 24/7 NOC hotline

## License

Internal use only - Grid Operations Department