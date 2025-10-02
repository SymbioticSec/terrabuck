# Insurance Claims Processing Platform - Terraform Infrastructure

This Terraform configuration deploys a comprehensive insurance claims processing platform on Google Cloud Platform (GCP). The platform automates claim intake, document analysis, fraud detection, and approval workflows for a mid-size insurance company processing 10,000+ claims monthly.

## Architecture Overview

The platform implements an event-driven microservices architecture with the following components:

- **Claims Document Storage**: Secure Google Cloud Storage buckets for claim documents and audit logs
- **Claims Processing Engine**: Compute Engine instance running the core workflow engine
- **Document Analysis Function**: Cloud Function for OCR processing and document classification
- **Fraud Detection Service**: Cloud Run service for ML-based fraud scoring
- **Claims Database**: Cloud SQL PostgreSQL database for claim records and customer data
- **Notification Queue**: Pub/Sub topic for asynchronous message processing
- **API Gateway**: Load balancer and SSL termination for external integrations

## Network Architecture

- **VPC**: Single VPC with three subnets (public, private, data)
- **Public Subnet**: API gateway and load balancers (10.0.1.0/24)
- **Private Subnet**: Application servers (10.0.2.0/24)
- **Data Subnet**: Cloud SQL database (10.0.3.0/24)
- **NAT Gateway**: Outbound internet access for private resources

## Prerequisites

1. **GCP Project**: Active GCP project with billing enabled
2. **APIs Enabled**:
   - Compute Engine API
   - Cloud SQL API
   - Cloud Functions API
   - Cloud Run API
   - Cloud Storage API
   - Pub/Sub API
   - VPC Access API
   - Service Networking API

3. **Terraform**: Version >= 1.0
4. **Authentication**: GCP service account key or `gcloud auth application-default login`

## Required Files

Before deployment, create a dummy function source file:
```bash
echo "def analyze_document(event, context): pass" > main.py
zip function-source.zip main.py
```

## Deployment Instructions

1. **Clone and Initialize**:
   ```bash
   git clone <repository>
   cd insurance-claims-terraform
   terraform init
   ```

2. **Configure Variables**:
   Create `terraform.tfvars`:
   ```hcl
   project_id     = "your-gcp-project-id"
   project_number = "123456789012"
   region         = "us-central1"
   zone           = "us-central1-a"
   domain         = "yourcompany.com"
   ```

3. **Plan Deployment**:
   ```bash
   terraform plan
   ```

4. **Deploy Infrastructure**:
   ```bash
   terraform apply
   ```

5. **Verify Deployment**:
   ```bash
   terraform output
   ```

## Post-Deployment Configuration

1. **Database Setup**:
   - Connect to Cloud SQL instance
   - Create application database schema
   - Configure database users and permissions

2. **Application Deployment**:
   - Deploy claims processing application to Compute Engine
   - Configure Cloud Function with actual document analysis code
   - Deploy fraud detection model to Cloud Run

3. **Security Configuration**:
   - Review and tighten firewall rules
   - Configure SSL certificates
   - Set up monitoring and alerting

## Resource Naming Convention

All resources follow the pattern: `insurance-claims-processing-platform-{resource-type}-{identifier}`

## Security Features

- Private subnets for application and database tiers
- VPC-native networking with private Google access
- SSL/TLS encryption for data in transit
- Cloud SQL with private IP and SSL enforcement
- IAM service accounts with least privilege
- Audit logging for storage access
- Network firewall rules

## Monitoring and Logging

- Cloud SQL audit logs
- Storage access logging
- VPC flow logs (can be enabled)
- Cloud Function execution logs
- Cloud Run request logs

## Cost Optimization

- Uses cost-effective machine types (e2-medium, db-f1-micro)
- Lifecycle policies for storage buckets
- Auto-scaling for Cloud Run services
- Preemptible instances can be configured for non-critical workloads

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will permanently delete all data and resources.

## Support and Troubleshooting

Common issues and solutions:

1. **API Not Enabled**: Enable required GCP APIs in the console
2. **Quota Exceeded**: Request quota increases for compute resources
3. **Permission Denied**: Verify service account has necessary IAM roles
4. **Network Connectivity**: Check VPC peering and firewall rules

## Compliance Notes

This infrastructure is designed to support:
- SOC 2 compliance requirements
- GDPR data protection standards
- Insurance industry regulatory requirements
- PCI DSS for payment data (additional configuration required)

For production deployments, additional security hardening and compliance configurations may be required based on specific regulatory requirements.