# Fleet Management and GPS Tracking Platform

This Terraform configuration deploys a comprehensive fleet management platform on Microsoft Azure for logistics companies to track vehicle locations, monitor driver behavior, manage fuel consumption, and optimize delivery routes.

## Architecture Overview

The platform implements an event-driven microservices architecture with the following components:

- **Vehicle Telemetry Ingestion**: Azure Event Hubs for high-frequency GPS and diagnostic data
- **Telemetry Processor**: Azure Functions for real-time data processing and analytics
- **Fleet Database**: Azure SQL Database for vehicle profiles and historical data
- **Fleet Management Web App**: Azure App Service for dashboard and management interface
- **Map Tile Storage**: Azure Storage Account with CDN for cached map data
- **Application Gateway**: Load balancer with SSL termination and WAF protection

## Network Architecture

- **Public Subnet**: Application Gateway (10.0.1.0/24)
- **Private Subnet**: App Service and Functions (10.0.2.0/24)
- **Data Subnet**: SQL Database with service endpoints (10.0.3.0/24)

## Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.0 installed
- Azure subscription with appropriate permissions

## Deployment Instructions

1. **Clone and Navigate**
   ```bash
   git clone <repository-url>
   cd fleet-management-terraform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review and Customize Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

4. **Plan Deployment**
   ```bash
   terraform plan
   ```

5. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

6. **Verify Deployment**
   ```bash
   terraform output
   ```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Name of the fleet management project | `fleet-management-gps` |
| `environment` | Environment name (dev, staging, prod) | `dev` |
| `location` | Azure region for deployment | `East US` |
| `sql_admin_username` | SQL Server administrator username | `sqladmin` |
| `sql_admin_password` | SQL Server administrator password | *Required* |

## Post-Deployment Configuration

### 1. Database Setup
```sql
-- Connect to the SQL database and create initial schema
CREATE TABLE Vehicles (
    VehicleId INT PRIMARY KEY IDENTITY,
    VIN VARCHAR(17) UNIQUE NOT NULL,
    LicensePlate VARCHAR(20),
    Make VARCHAR(50),
    Model VARCHAR(50),
    Year INT
);

CREATE TABLE TelemetryData (
    Id BIGINT PRIMARY KEY IDENTITY,
    VehicleId INT FOREIGN KEY REFERENCES Vehicles(VehicleId),
    Timestamp DATETIME2,
    Latitude DECIMAL(10,8),
    Longitude DECIMAL(11,8),
    Speed DECIMAL(5,2),
    FuelLevel DECIMAL(5,2)
);
```

### 2. Function App Deployment
Deploy the telemetry processing functions:
```bash
func azure functionapp publish <function-app-name>
```

### 3. Web Application Deployment
Deploy the fleet management web application:
```bash
az webapp deployment source config-zip \
  --resource-group <resource-group-name> \
  --name <web-app-name> \
  --src fleet-management-app.zip
```

## Monitoring and Maintenance

- **Application Insights**: Monitor application performance and errors
- **SQL Database Metrics**: Track database performance and query execution
- **Event Hub Metrics**: Monitor message throughput and processing latency
- **Storage Analytics**: Track blob access patterns and CDN performance

## Security Considerations

- SQL Server firewall rules restrict database access
- Network Security Groups control traffic between subnets
- Storage containers use appropriate access policies
- Application Gateway provides WAF protection
- All resources use managed identities where possible

## Scaling Considerations

- Event Hub partitions can be increased for higher throughput
- App Service Plan can be scaled up/out based on demand
- SQL Database can use elastic pools for multiple databases
- Function App scales automatically based on Event Hub triggers

## Cost Optimization

- Use Azure Reserved Instances for predictable workloads
- Implement lifecycle policies for storage accounts
- Monitor and optimize SQL Database DTU usage
- Use CDN caching to reduce storage egress costs

## Troubleshooting

### Common Issues

1. **SQL Connection Failures**
   - Verify firewall rules allow your IP address
   - Check connection string format and credentials

2. **Function App Not Triggering**
   - Verify Event Hub connection string is correct
   - Check Function App logs for binding errors

3. **Web App 502/503 Errors**
   - Check App Service logs for startup errors
   - Verify database connectivity from App Service

### Support

For technical support and questions:
- Review Azure documentation for specific services
- Check Terraform Azure provider documentation
- Monitor Azure Service Health for platform issues

## License

This project is licensed under the MIT License - see the LICENSE file for details.