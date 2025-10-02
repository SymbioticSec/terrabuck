# Digital Library Content Management Platform

A comprehensive digital library platform for academic institutions that manages digital book collections, handles user authentication, provides full-text search capabilities, and tracks usage analytics.

## Architecture Overview

This Terraform configuration deploys a complete digital library platform on Google Cloud Platform with the following components:

### Core Components

1. **Content Storage** - Google Cloud Storage bucket for digital books, documents, and media files
2. **API Gateway** - Cloud Run service handling authentication, authorization, and request routing
3. **Search Service** - Cloud Run service providing full-text search capabilities
4. **User Database** - Cloud SQL PostgreSQL instance storing user profiles and authentication data
5. **Metadata Database** - Cloud SQL PostgreSQL instance storing book metadata and catalog information
6. **Analytics Processor** - Cloud Function processing usage events and generating reports
7. **Usage Logs** - Cloud Storage bucket for application logs and audit trails

### Network Architecture

- **VPC Network**: Single VPC with three subnets across multiple zones
- **Public Subnet**: Load balancers and external access (10.0.1.0/24)
- **Private Subnet**: Cloud Run services (10.0.2.0/24)
- **Data Subnet**: Database instances (10.0.3.0/24)

## Prerequisites

- Google Cloud Platform account with billing enabled
- Terraform >= 1.0 installed
- `gcloud` CLI installed and authenticated
- Required APIs enabled:
  - Cloud Run API
  - Cloud SQL API
  - Cloud Functions API
  - Cloud Storage API
  - Compute Engine API

## Deployment Instructions

### 1. Enable Required APIs

```bash
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable compute.googleapis.com
```

### 2. Set Up Authentication

```bash
gcloud auth application-default login
```

### 3. Configure Variables

Create a `terraform.tfvars` file:

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
zone       = "us-central1-a"
environment = "prod"
university_domain = "your-university.edu"
```

### 4. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 5. Post-Deployment Setup

After deployment, you'll need to:

1. **Upload Application Code**: Deploy your application containers to the Cloud Run services
2. **Initialize Databases**: Run database migrations and seed data
3. **Configure DNS**: Point your domain to the Cloud Run services
4. **Upload Function Code**: Package and upload the analytics function code

## Service Endpoints

After deployment, the following endpoints will be available:

- **API Gateway**: `https://digital-library-content-management-platform-run-api-gateway-[hash].a.run.app`
- **Search Service**: `https://digital-library-content-management-platform-run-search-[hash].a.run.app`

## Database Connections

### User Database
- **Connection Name**: Available in Terraform output `user_database_connection_name`
- **Database Name**: `users`
- **Connection String**: `postgresql://user:pass@[connection_name]/users`

### Metadata Database
- **Connection Name**: Available in Terraform output `metadata_database_connection_name`
- **Database Name**: `metadata`
- **Connection String**: `postgresql://user:pass@[connection_name]/metadata`

## Storage Buckets

### Content Storage
- **Purpose**: Digital books, documents, and media files
- **Lifecycle**: Files deleted after 365 days
- **Versioning**: Enabled

### Usage Logs
- **Purpose**: Application logs and audit trails
- **Lifecycle**: Files deleted after 2555 days (7 years)
- **Trigger**: Analytics function processes new log files

## Security Features

- **Network Isolation**: Services deployed in private subnets
- **Service Accounts**: Dedicated service accounts for each component
- **IAM Roles**: Principle of least privilege access
- **SSL/TLS**: Encrypted communication between services
- **Database Security**: SSL connections and backup encryption

## Monitoring and Logging

- **Cloud Logging**: Automatic log collection from all services
- **Cloud Monitoring**: Built-in metrics and alerting
- **Audit Trails**: Comprehensive logging for compliance

## Scaling Configuration

### Cloud Run Services
- **CPU**: 1000m (1 vCPU) per instance
- **Memory**: 512Mi per instance
- **Auto-scaling**: Based on request volume

### Cloud SQL Databases
- **Tier**: db-f1-micro (development/testing)
- **Scaling**: Manual scaling required for production

### Cloud Functions
- **Memory**: 256MB
- **Timeout**: 60 seconds
- **Concurrency**: 1000 concurrent executions

## Cost Optimization

- **Storage Lifecycle**: Automatic deletion of old files
- **Database Tier**: Optimized for development (upgrade for production)
- **Cloud Run**: Pay-per-request pricing model
- **Regional Resources**: Single region deployment to minimize costs

## Backup and Recovery

- **Database Backups**: Automated daily backups (configure retention)
- **Storage Versioning**: Object versioning enabled
- **Cross-Region Replication**: Configure for production environments

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure service accounts have required IAM roles
2. **Network Connectivity**: Verify firewall rules and subnet configurations
3. **Database Connections**: Check SSL requirements and authorized networks
4. **Function Deployment**: Ensure source code is uploaded to storage bucket

### Useful Commands

```bash
# Check Cloud Run service status
gcloud run services list --region=us-central1

# View database instances
gcloud sql instances list

# Check function logs
gcloud functions logs read analytics_processor --region=us-central1

# Test connectivity
gcloud compute ssh [instance-name] --zone=us-central1-a
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all data and resources. Ensure you have backups before proceeding.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Google Cloud documentation
3. Contact your system administrator
4. Submit issues to the project repository

## License

This infrastructure configuration is provided under the MIT License. See LICENSE file for details.