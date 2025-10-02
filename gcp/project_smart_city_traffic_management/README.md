# Smart City Traffic Management Platform

This Terraform configuration deploys a comprehensive Smart City Traffic Management Platform on Google Cloud Platform. The system processes real-time data from IoT sensors, traffic cameras, and GPS devices to optimize traffic flow and manage incidents.

## Architecture Overview

The platform consists of the following components:

- **Sensor Data Ingestion**: Pub/Sub topic for real-time sensor data streams
- **Traffic Data Processor**: Cloud Function for processing sensor data and calculating traffic patterns
- **Traffic Database**: Cloud SQL PostgreSQL instance for storing processed traffic data
- **Operator Dashboard**: Compute Engine instance hosting the web application for traffic operators
- **Public API Gateway**: Cloud Run service providing public APIs for mobile apps
- **Static Assets**: Cloud Storage bucket for dashboard assets and traffic images

## Prerequisites

1. Google Cloud Platform account with billing enabled
2. Terraform >= 1.0 installed
3. `gcloud` CLI installed and authenticated
4. Required APIs enabled:
   - Compute Engine API
   - Cloud SQL API
   - Cloud Functions API
   - Cloud Run API
   - Pub/Sub API
   - Cloud Storage API
   - VPC Access API
   - Service Networking API

## Deployment Instructions

### Step 1: Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable vpcaccess.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

### Step 2: Prepare Function Source Code

Create a placeholder function source file:

```bash
echo "def process_traffic_data(event, context): pass" > main.py
zip function-source.zip main.py
```

### Step 3: Set Variables

Create a `terraform.tfvars` file:

```hcl
project_id     = "your-gcp-project-id"
project_number = "your-gcp-project-number"
region         = "us-central1"
environment    = "prod"
```

### Step 4: Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

## Network Architecture

- **VPC**: Custom VPC with public and private subnets
- **Public Subnet**: 10.0.1.0/24 - For load balancers and NAT gateways
- **Private Subnet**: 10.0.2.0/24 - For compute instances and internal services
- **Database**: Private IP only, accessible via VPC peering

## Security Features

- Private IP for Cloud SQL database
- VPC-native networking
- Service accounts with minimal permissions
- Encrypted storage and transit
- Network firewall rules

## Monitoring and Logging

The platform includes:
- Cloud SQL query insights
- Cloud Function execution logs
- VPC flow logs (when enabled)
- Cloud Run request logging

## Scaling Considerations

- Cloud Run auto-scales based on traffic
- Cloud Functions scale automatically with Pub/Sub messages
- Cloud SQL can be upgraded to higher tiers as needed
- Compute Engine instances can be replaced with managed instance groups

## Cost Optimization

- Uses cost-effective machine types (e2-medium, db-f1-micro)
- Cloud Run scales to zero when not in use
- Cloud Functions only charge for execution time
- Storage buckets use standard storage class

## Maintenance

Regular maintenance tasks:
1. Monitor Cloud SQL performance and upgrade if needed
2. Review and rotate service account keys
3. Update Cloud Function runtime versions
4. Monitor storage bucket usage and implement lifecycle policies

## Troubleshooting

Common issues and solutions:

1. **Database connection issues**: Ensure VPC peering is properly configured
2. **Function timeouts**: Increase memory allocation or optimize code
3. **API gateway errors**: Check service account permissions
4. **Network connectivity**: Verify firewall rules and VPC configuration

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all data and resources.