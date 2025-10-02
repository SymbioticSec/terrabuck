# Telehealth Video Consultation Platform - Azure Infrastructure

This Terraform configuration deploys a comprehensive HIPAA-compliant telehealth platform on Microsoft Azure, enabling secure video consultations between healthcare providers and patients.

## Architecture Overview

The platform implements a microservices architecture with the following components:

- **Application Gateway**: Load balancing, SSL termination, and WAF protection
- **Web Application**: Patient and provider portals for scheduling and consultations
- **Video Streaming Service**: Real-time video streaming with Azure Media Services
- **SQL Database**: Stores appointments, schedules, and consultation metadata
- **Medical Records Storage**: Secure blob storage for recordings and documents
- **Notification Service**: Azure Functions for appointment reminders and alerts

## Network Architecture

- **Public Subnet**: Application Gateway with public IP
- **Private Subnet**: App Services and Functions with VNet integration
- **Data Subnet**: SQL Database with private endpoints

## Prerequisites

1. Azure CLI installed and configured
2. Terraform >= 1.0 installed
3. Appropriate Azure subscription with required permissions
4. Owner or Contributor role on the target subscription

## Deployment Instructions

### Step 1: Clone and Initialize

```bash
git clone <repository-url>
cd telehealth-infrastructure
terraform init
```

### Step 2: Configure Variables

Create a `terraform.tfvars` file:

```hcl
location = "East US"
environment = "prod"
sql_admin_username = "your-admin-username"
sql_admin_password = "your-secure-password"
```

### Step 3: Plan and Deploy

```bash
# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### Step 4: Post-Deployment Configuration

1. **Configure Application Gateway Backend Pool**:
   - Add the web app to the backend pool
   - Configure health probes

2. **Set up Database Schema**:
   - Connect to the SQL database
   - Create required tables for appointments and user data

3. **Configure Media Services**:
   - Set up streaming endpoints
   - Configure content protection policies

4. **Deploy Application Code**:
   - Deploy web application to App Service
   - Deploy notification functions to Function App

## Security Considerations

This infrastructure includes several security features:

- Web Application Firewall (WAF) protection
- Virtual network isolation
- Key Vault for secrets management
- SQL Database with TDE encryption
- Storage account encryption at rest
- Network security groups

## HIPAA Compliance Features

- Audit logging enabled
- Encryption at rest and in transit
- Private endpoints for database access
- Access controls and RBAC
- Backup and retention policies

## Monitoring and Logging

The platform includes:

- Azure Monitor integration
- Application Insights for web app monitoring
- SQL Database auditing
- Storage account logging
- Function app monitoring

## Estimated Costs

Monthly cost estimates (East US region):
- Application Gateway (WAF_v2): ~$250
- App Service (P1v2): ~$75
- SQL Database (S2): ~$30
- Storage Accounts: ~$20
- Media Services: Variable based on usage
- Function App: Pay-per-execution

## Backup and Disaster Recovery

- SQL Database automated backups (30-day retention)
- Storage account geo-redundant replication
- Application code deployment automation
- Infrastructure as Code for rapid recovery

## Scaling Considerations

- Application Gateway supports auto-scaling
- App Service can scale horizontally
- SQL Database supports elastic pools
- Function Apps scale automatically
- Media Services scales based on demand

## Maintenance

Regular maintenance tasks:
- Update Terraform provider versions
- Review and update WAF rules
- Monitor security alerts
- Update application dependencies
- Review access logs and audit trails

## Troubleshooting

Common issues and solutions:

1. **Deployment Failures**:
   - Check Azure resource quotas
   - Verify naming conventions (globally unique names)
   - Ensure proper permissions

2. **Connectivity Issues**:
   - Verify network security group rules
   - Check private endpoint configurations
   - Validate DNS resolution

3. **Performance Issues**:
   - Monitor Application Insights metrics
   - Check SQL Database DTU usage
   - Review storage account performance

## Support

For technical support:
- Review Azure documentation
- Check Terraform provider documentation
- Monitor Azure Service Health
- Review application logs in Application Insights

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources and data. Ensure you have proper backups before proceeding.