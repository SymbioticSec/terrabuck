# Smart Manufacturing Execution System (MES) - Terraform Infrastructure

This Terraform configuration deploys a comprehensive Manufacturing Execution System (MES) on Google Cloud Platform for automotive parts manufacturing. The system handles real-time sensor data from 50+ production machines, processes quality inspection data, and generates compliance reports for ISO 9001 certification.

## Architecture Overview

The infrastructure implements an IoT data pipeline with the following components:

- **Sensor Data Ingestion**: Pub/Sub topics for high-frequency sensor data
- **Data Processing Pipeline**: Cloud Functions for real-time anomaly detection and OEE calculations
- **Production Database**: Cloud SQL PostgreSQL for work orders and quality records
- **Time Series Storage**: Cloud Storage buckets for historical data archival
- **MES Application**: Compute instance hosting the web application
- **Reporting Service**: Cloud Functions for automated compliance reporting

## Network Topology

- **VPC Structure**: Single VPC with three subnets
  - Public subnet (10.0.1.0/24): Load balancer
  - Private subnet (10.0.2.0/24): Application servers
  - Data subnet (10.0.3.0/24): Database with Cloud SQL proxy

## Prerequisites

1. Google Cloud Platform account with billing enabled
2. Terraform >= 1.0 installed
3. Google Cloud SDK installed and authenticated
4. Required APIs will be enabled automatically

## Deployment Instructions

### Step 1: Clone and Configure

```bash
git clone <repository-url>
cd smart-manufacturing-mes-terraform
```

### Step 2: Set Variables

Create a `terraform.tfvars` file:

```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
zone       = "us-central1-a"
environment = "prod"
db_password = "your-secure-database-password"
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Plan Deployment

```bash
terraform plan
```

### Step 5: Deploy Infrastructure

```bash
terraform apply
```

### Step 6: Upload Function Source Code

After deployment, upload the Cloud Function source code:

```bash
# Create placeholder function source files
echo "def process_sensor_data(event, context): pass" > function.py
zip function-source.zip function.py
gsutil cp function-source.zip gs://$(terraform output -raw time_series_storage_bucket)/

echo "def generate_reports(event, context): pass" > reporting.py
zip reporting-source.zip reporting.py
gsutil cp reporting-source.zip gs://$(terraform output -raw time_series_storage_bucket)/
```

### Step 7: Create Startup Script

Create `startup-script.sh` for the MES application:

```bash
#!/bin/bash
apt-get update
apt-get install -y nginx python3 python3-pip
systemctl start nginx
systemctl enable nginx

# Install MES application dependencies
pip3 install flask psycopg2-binary google-cloud-sql-connector

# Configure MES application (placeholder)
echo "MES Application installed successfully" > /var/log/mes-install.log
```

## Post-Deployment Configuration

### Database Setup

1. Connect to the Cloud SQL instance using the Cloud SQL proxy
2. Create necessary tables for manufacturing data:
   - work_orders
   - quality_inspections
   - production_metrics
   - equipment_status

### IoT Device Configuration

1. Configure production line sensors to publish to the Pub/Sub topic
2. Set up authentication using service account keys
3. Implement rate limiting for high-frequency sensor data

### Application Configuration

1. SSH into the MES application instance
2. Configure database connections using the provided connection string
3. Set up SSL certificates for HTTPS access
4. Configure monitoring and alerting

## Monitoring and Maintenance

### Key Metrics to Monitor

- Pub/Sub message throughput and latency
- Cloud Function execution times and error rates
- Database connection pool utilization
- Storage bucket usage and costs
- Compute instance CPU and memory usage

### Backup Strategy

- Cloud SQL automated backups are enabled (daily at 3:00 AM)
- Storage buckets have lifecycle policies for cost optimization
- Function source code should be version controlled

### Security Considerations

- Database access is restricted to authorized networks
- All inter-service communication uses service accounts
- Firewall rules limit access to necessary ports only
- OS Login is enabled for centralized SSH key management

## Scaling Considerations

### Horizontal Scaling

- Add more compute instances to the instance group
- Increase Pub/Sub topic partitions for higher throughput
- Scale Cloud Functions automatically based on demand

### Vertical Scaling

- Increase database tier for higher performance
- Upgrade compute instance machine types
- Adjust Cloud Function memory allocation

## Troubleshooting

### Common Issues

1. **Function deployment fails**: Ensure source code is uploaded to the storage bucket
2. **Database connection errors**: Check firewall rules and authorized networks
3. **High latency**: Monitor Pub/Sub subscription backlog and function cold starts

### Logs and Debugging

- Cloud Function logs: `gcloud functions logs read FUNCTION_NAME`
- Compute instance logs: SSH and check `/var/log/`
- Database logs: Available in Cloud SQL console

## Cost Optimization

- Use preemptible instances for non-critical workloads
- Implement storage lifecycle policies
- Monitor and adjust Cloud Function memory allocation
- Use committed use discounts for predictable workloads

## Compliance and Auditing

The system supports ISO 9001 compliance through:
- Complete audit trails in database logs
- Immutable storage of quality inspection records
- Automated compliance report generation
- Role-based access controls

## Support and Maintenance

For production support:
1. Monitor system health dashboards
2. Set up alerting for critical failures
3. Maintain regular backup verification
4. Keep function code and dependencies updated

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources and data. Ensure backups are created before destruction.