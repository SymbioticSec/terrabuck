# Multi-Location Restaurant POS System Infrastructure

This Terraform configuration deploys a comprehensive cloud-based Point of Sale (POS) system for a restaurant chain with 15+ locations. The system provides real-time order processing, inventory management, payment processing, and centralized reporting capabilities.

## Architecture Overview

The infrastructure implements a microservices architecture with the following components:

- **GKE Cluster**: Hosts containerized POS application microservices
- **Cloud SQL**: PostgreSQL database for transactional data
- **Cloud Storage**: Inventory data, menu images, and backup files
- **Cloud Functions**: Serverless payment processing
- **Load Balancer**: Global HTTPS load balancer with SSL termination
- **VPC Network**: Secure network with public, private, and data subnets

## Prerequisites

1. **Google Cloud Platform Account**: Active GCP project with billing enabled
2. **Terraform**: Version 1.0 or higher
3. **gcloud CLI**: Authenticated with appropriate permissions
4. **Domain**: Valid domain name for SSL certificate

## Required GCP APIs

Enable the following APIs in your GCP project:

```bash
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable vpcaccess.googleapis.com
```

## Deployment Instructions

### Step 1: Clone and Prepare

```bash
git clone <repository-url>
cd restaurant-pos-infrastructure
```

### Step 2: Create Function Source Archive

Create a dummy Cloud Function source file:

```bash
mkdir -p temp-function
cd temp-function
cat > main.py << 'EOF'
def process_payment(request):
    return {'status': 'success', 'message': 'Payment processed'}
EOF
zip -r ../payment-processor-source.zip .
cd ..
rm -rf temp-function
```

### Step 3: Configure Variables

Create a `terraform.tfvars` file:

```hcl
project_id       = "your-gcp-project-id"
region          = "us-central1"
domain_name     = "pos.your-domain.com"
developer_email = "developer@your-company.com"
environment     = "prod"
```

### Step 4: Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### Step 5: Post-Deployment Configuration

1. **Configure kubectl**:
   ```bash
   gcloud container clusters get-credentials multi-location-restaurant-pos-system-cluster-pos-application --region=us-central1
   ```

2. **Verify SSL Certificate**:
   ```bash
   gcloud compute ssl-certificates describe multi-location-restaurant-pos-system-cert-ssl --global
   ```

3. **Test Database Connection**:
   ```bash
   gcloud sql connect multi-location-restaurant-pos-system-database-pos --user=postgres
   ```

## Security Features

- **Network Isolation**: VPC with separate subnets for different tiers
- **Encryption**: KMS-encrypted storage and SSL/TLS in transit
- **Private Database**: Cloud SQL with private IP only
- **Service Accounts**: Dedicated service accounts with minimal permissions
- **Workload Identity**: Secure pod-to-GCP service authentication

## Monitoring and Maintenance

### Health Checks

The system includes HTTP health checks for the GKE backend service. Monitor the health status:

```bash
gcloud compute health-checks describe multi-location-restaurant-pos-system-healthcheck-http
```

### Database Maintenance

Regular maintenance tasks:

```bash
# Check database status
gcloud sql instances describe multi-location-restaurant-pos-system-database-pos

# View database logs
gcloud sql instances describe multi-location-restaurant-pos-system-database-pos --format="value(settings.databaseFlags)"
```

### Storage Management

Monitor storage usage:

```bash
# List bucket contents
gsutil ls -la gs://$(terraform output -raw inventory_bucket_name)

# Check bucket versioning
gsutil versioning get gs://$(terraform output -raw inventory_bucket_name)
```

## Scaling Considerations

### GKE Cluster Scaling

To scale the node pool:

```bash
gcloud container clusters resize multi-location-restaurant-pos-system-cluster-pos-application --num-nodes=4 --region=us-central1
```

### Database Scaling

Upgrade the database tier by modifying the `database_tier` variable and running `terraform apply`.

## Troubleshooting

### Common Issues

1. **SSL Certificate Provisioning**: Managed certificates can take up to 60 minutes to provision
2. **VPC Connector**: Ensure the IP range doesn't conflict with existing subnets
3. **Service Account Permissions**: Verify service accounts have necessary IAM roles

### Logs and Debugging

```bash
# GKE cluster logs
gcloud logging read "resource.type=gke_cluster" --limit=50

# Cloud Function logs
gcloud functions logs read multi-location-restaurant-pos-system-function-payment-processor

# Load balancer logs
gcloud logging read "resource.type=http_load_balancer" --limit=50
```

## Cost Optimization

- Use preemptible nodes for non-critical workloads
- Implement lifecycle policies for storage buckets
- Monitor and adjust database tier based on usage
- Set up budget alerts for cost control

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all data and resources. Ensure you have proper backups before proceeding.

## Support

For technical support and questions:
- Review GCP documentation for specific services
- Check Terraform provider documentation
- Monitor system logs for troubleshooting
- Implement proper backup and disaster recovery procedures

## Compliance Notes

This infrastructure is designed to support PCI DSS compliance requirements for payment processing. Ensure proper security controls are implemented at the application level and conduct regular security assessments.