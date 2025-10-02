# HIPAA-Compliant Patient Portal Infrastructure

This Terraform configuration deploys a HIPAA-compliant patient portal infrastructure on Google Cloud Platform. The architecture includes a React frontend, Node.js API backend, PostgreSQL database, and secure document storage with comprehensive audit logging.

## Architecture Overview

The infrastructure implements a three-tier architecture with proper network segmentation:

- **Public Tier**: Load balancer with SSL termination
- **Private Tier**: Web frontend and API backend instances
- **Data Tier**: Cloud SQL PostgreSQL database and encrypted storage

## Components Deployed

1. **Web Frontend** (`google_compute_instance_group`)
   - React-based patient portal with auto-scaling
   - Deployed in private subnet with load balancer access

2. **API Backend** (`google_compute_instance_group`)
   - Node.js API server handling authentication and PHI
   - Connects to database and audit logging

3. **Patient Database** (`google_sql_database_instance`)
   - PostgreSQL with encryption at rest
   - Private network connectivity only

4. **Document Storage** (`google_storage_bucket`)
   - Customer-managed encryption for medical documents
   - Versioning and lifecycle policies enabled

5. **Load Balancer** (`google_compute_global_forwarding_rule`)
   - Global HTTP(S) load balancer
   - Health checks and auto-scaling integration

6. **KMS Encryption** (`google_kms_crypto_key`)
   - Customer-managed encryption keys
   - Used for database and storage encryption

7. **Audit Logging** (`google_logging_sink`)
   - Centralized audit trail for HIPAA compliance
   - 7-year retention policy

## Prerequisites

1. Google Cloud Project with billing enabled
2. Terraform >= 1.0 installed
3. Google Cloud SDK configured
4. Required APIs enabled:
   - Compute Engine API
   - Cloud SQL Admin API
   - Cloud Storage API
   - Cloud KMS API
   - Service Networking API

## Required APIs

Enable the following APIs in your GCP project:

```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable logging.googleapis.com
```

## Deployment Instructions

1. **Clone and Configure**
   ```bash
   git clone <repository-url>
   cd hipaa-patient-portal-terraform
   ```

2. **Set Variables**
   Create a `terraform.tfvars` file:
   ```hcl
   project_id     = "your-gcp-project-id"
   project_number = "123456789012"
   region         = "us-central1"
   environment    = "prod"
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan Deployment**
   ```bash
   terraform plan
   ```

5. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

## Security Features

- **Encryption**: Customer-managed KMS keys for data at rest
- **Network Security**: VPC with private subnets and firewall rules
- **Access Control**: Service accounts with minimal permissions
- **Audit Logging**: Comprehensive logging for HIPAA compliance
- **SSL/TLS**: Encrypted connections for data in transit

## HIPAA Compliance Features

- **Administrative Safeguards**: IAM roles and access controls
- **Physical Safeguards**: Google Cloud's certified data centers
- **Technical Safeguards**: Encryption, audit logs, access controls

## Monitoring and Maintenance

- Health checks monitor application availability
- Auto-scaling responds to traffic demands
- Audit logs provide compliance reporting
- Backup and recovery procedures included

## Cost Optimization

- Right-sized instance types for workload
- Lifecycle policies for storage cost management
- Regional deployment reduces data transfer costs

## Troubleshooting

Common issues and solutions:

1. **API Not Enabled**: Ensure all required APIs are enabled
2. **Permissions**: Verify service account has necessary roles
3. **Networking**: Check firewall rules and subnet configurations
4. **Database**: Verify private service networking connection

## Security Considerations

This infrastructure includes several security best practices:
- Private networking for database access
- Customer-managed encryption keys
- Comprehensive audit logging
- Network segmentation with firewall rules

## Compliance Notes

This configuration addresses HIPAA requirements for:
- Access controls and user authentication
- Audit logs and monitoring
- Data encryption at rest and in transit
- Network security and segmentation

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Google Cloud documentation
3. Contact your cloud architecture team

## License

This infrastructure code is provided as-is for educational and deployment purposes.