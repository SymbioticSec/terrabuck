# Telehealth Video Consultation Platform

This Terraform configuration deploys a HIPAA-compliant telehealth platform on Google Cloud Platform, enabling secure video consultations between healthcare providers and patients.

## Architecture Overview

The platform implements a microservices architecture with the following components:

- **Patient Portal App**: Frontend application served via managed instance groups with load balancing
- **Appointment API**: Cloud Run service managing patient appointments and provider schedules
- **Video Service**: Cloud Run service handling WebRTC signaling for video consultations
- **Patient Database**: PostgreSQL database storing patient information and consultation history
- **Medical Records Storage**: Cloud Storage bucket for medical documents and consultation recordings
- **Audit Logging**: Centralized logging system for compliance and monitoring

## Network Architecture

- **VPC**: Custom VPC with three-tier subnet design
  - Public subnet (10.0.1.0/24): Load balancer
  - Private subnet (10.0.2.0/24): Application tier
  - Data subnet (10.0.3.0/24): Database tier
- **Security**: Firewall rules, private Google access, Cloud NAT for outbound connectivity

## Prerequisites

1. Google Cloud Platform account with billing enabled
2. Terraform >= 1.0 installed
3. Google Cloud SDK installed and authenticated
4. Required APIs enabled:
   - Compute Engine API
   - Cloud Run API
   - Cloud SQL API
   - Cloud Storage API
   - Cloud DNS API
   - Service Networking API

## Deployment Instructions

### 1. Clone and Configure

```bash
git clone <repository-url>
cd telehealth-platform-terraform
```

### 2. Set Required Variables

Create a `terraform.tfvars` file:

```hcl
project_id  = "your-gcp-project-id"
region      = "us-central1"
zone        = "us-central1-a"
domain_name = "your-domain.com"
db_password = "your-secure-database-password"
environment = "dev"
```

### 3. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 4. Post-Deployment Configuration

1. **DNS Configuration**: Update your domain's nameservers to use the ones output by the DNS managed zone
2. **SSL Certificate**: Configure SSL certificates for HTTPS access
3. **Application Deployment**: Deploy your application code to the Cloud Run services
4. **Database Schema**: Initialize the database with your application schema

## Security Features

- **Network Security**: Private subnets with controlled access
- **Data Encryption**: Encryption at rest for database and storage
- **Access Control**: IAM-based service account permissions
- **Audit Logging**: Comprehensive logging for compliance
- **Firewall Rules**: Restrictive network access controls

## Monitoring and Compliance

The platform includes:
- Audit logging to Cloud Storage for HIPAA compliance
- Health checks for application availability
- Versioning enabled on storage buckets
- Automatic backup configuration for the database

## Resource Naming Convention

All resources follow the pattern: `telehealth-video-consultation-platform-{resource-type}-{identifier}`

## Estimated Costs

- Compute instances: ~$50-100/month
- Cloud Run services: ~$20-50/month (depending on usage)
- Cloud SQL: ~$30-60/month
- Storage and networking: ~$10-30/month

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all data. Ensure you have backups before proceeding.

## Support

For issues or questions regarding this deployment, please refer to the Google Cloud documentation or contact your system administrator.