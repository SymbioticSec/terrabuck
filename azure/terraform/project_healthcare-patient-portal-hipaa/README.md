# Healthcare Patient Portal with HIPAA Compliance

This Terraform configuration deploys a comprehensive healthcare patient portal infrastructure on Microsoft Azure, designed to handle Protected Health Information (PHI) with HIPAA compliance requirements.

## Architecture Overview

The solution implements a multi-tier web application with the following components:

- **Web Frontend**: Azure App Service hosting the patient-facing portal
- **API Gateway**: Azure API Management for centralized API routing and security
- **Backend Services**: Container instances running microservices for patient data, appointments, and EHR integration
- **Patient Database**: Azure SQL Database with encryption for storing medical records
- **File Storage**: Azure Storage Account for medical documents and test results
- **Key Vault**: Centralized secrets management for database connections and API keys

## Network Architecture

- **Hub-Spoke VNet**: Segmented network with public, private, and data subnets
- **Public Subnet**: Web frontend with internet access
- **Private Subnet**: Backend services with internal communication
- **Data Subnet**: Database tier with restricted access

## Prerequisites

1. Azure CLI installed and configured
2. Terraform >= 1.0 installed
3. Appropriate Azure permissions for resource creation
4. Valid Azure subscription

## Deployment Instructions

### Step 1: Clone and Initialize

```bash
git clone <repository-url>
cd healthcare-patient-portal
terraform init
```

### Step 2: Configure Variables

Create a `terraform.tfvars` file with your specific values:

```hcl
location = "East US"
environment = "prod"
db_admin_username = "your-admin-username"
db_admin_password = "your-secure-password-12chars+"
publisher_name = "Your Healthcare Organization"
publisher_email = "admin@yourdomain.com"
```

### Step 3: Plan and Apply

```bash
# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### Step 4: Post-Deployment Configuration

1. **Configure API Management**: Set up APIs, policies, and authentication
2. **Deploy Application Code**: Deploy your web application to the App Service
3. **Configure Database Schema**: Set up patient tables and stored procedures
4. **Set up Monitoring**: Configure Azure Monitor and Log Analytics
5. **Configure Backup Policies**: Set up automated backups for database and storage

## Security Features

- **Network Segmentation**: Multi-tier network architecture with NSGs
- **Encryption**: Data encryption at rest and in transit
- **Identity Management**: Managed identities for service authentication
- **Secrets Management**: Azure Key Vault for sensitive configuration
- **Audit Logging**: Comprehensive logging for HIPAA compliance
- **Threat Detection**: SQL threat detection and security alerts

## HIPAA Compliance Considerations

This infrastructure provides the foundation for HIPAA compliance but requires additional configuration:

1. **Business Associate Agreements**: Ensure proper agreements with Microsoft Azure
2. **Access Controls**: Implement role-based access controls (RBAC)
3. **Audit Logging**: Configure comprehensive audit trails
4. **Data Backup**: Implement secure backup and recovery procedures
5. **Incident Response**: Establish security incident response procedures

## Monitoring and Maintenance

- **Azure Monitor**: Set up monitoring dashboards and alerts
- **Log Analytics**: Centralized logging for security and compliance
- **Security Center**: Enable Azure Security Center recommendations
- **Update Management**: Regular patching and updates
- **Performance Monitoring**: Application and database performance tracking

## Cost Optimization

- **Right-sizing**: Monitor resource utilization and adjust sizes
- **Reserved Instances**: Consider reserved capacity for predictable workloads
- **Storage Tiers**: Use appropriate storage tiers for different data types
- **Auto-scaling**: Implement auto-scaling for variable workloads

## Disaster Recovery

- **Geo-redundancy**: Configure geo-redundant storage and database backups
- **Backup Strategy**: Regular automated backups with point-in-time recovery
- **Failover Planning**: Document and test disaster recovery procedures

## Support and Troubleshooting

Common issues and solutions:

1. **Key Vault Access**: Ensure proper access policies are configured
2. **Network Connectivity**: Verify NSG rules and subnet configurations
3. **Database Connectivity**: Check firewall rules and connection strings
4. **Container Deployment**: Verify container images and environment variables

## Resource Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources and data. Ensure you have proper backups before proceeding.

## Contributing

1. Follow Azure naming conventions
2. Maintain security best practices
3. Update documentation for any changes
4. Test changes in non-production environments first

## License

This project is licensed under the MIT License - see the LICENSE file for details.