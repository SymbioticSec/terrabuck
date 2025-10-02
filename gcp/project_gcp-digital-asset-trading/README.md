# Digital Asset Trading Platform Infrastructure

This Terraform configuration deploys a comprehensive digital asset trading platform on Google Cloud Platform, designed to handle high-frequency cryptocurrency trading with real-time order matching and regulatory compliance features.

## Architecture Overview

The platform implements a microservices architecture with the following components:

- **Trading Engine Cluster**: High-performance compute instances running the core trading engine
- **Market Data Cache**: Redis instance for real-time market data and order books
- **Trading Database**: PostgreSQL database for user accounts, trading history, and balances
- **API Gateway**: Cloud Run service handling REST API requests and authentication
- **Compliance Storage**: Cloud Storage buckets for audit logs and regulatory data
- **Load Balancer**: Global load balancer distributing traffic across regions

## Network Architecture

- **Public Zone**: Load balancer and external-facing components
- **Private Zone**: API Gateway and application services
- **Data Zone**: Trading engine, database, and cache systems

## Prerequisites

1. Google Cloud Platform account with billing enabled
2. Terraform >= 1.0 installed
3. Google Cloud SDK installed and authenticated
4. Required APIs enabled:
   - Compute Engine API
   - Cloud SQL API
   - Cloud Run API
   - Redis API
   - Cloud Storage API

## Deployment Instructions

### 1. Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable redis.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable vpcaccess.googleapis.com
```

### 2. Set Up Authentication

```bash
gcloud auth application-default login
```

### 3. Configure Variables

Create a `terraform.tfvars` file:

```hcl
project_id = "your-gcp-project-id"
region = "us-central1"
database_password = "your-secure-database-password"
trading_engine_instance_count = 3
redis_memory_size = 4
database_tier = "db-standard-2"
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 5. Verify Deployment

After deployment, verify the components:

```bash
# Check load balancer IP
terraform output load_balancer_ip

# Check API Gateway URL
terraform output api_gateway_url

# Test connectivity
curl http://$(terraform output -raw load_balancer_ip)
```

## Configuration Details

### Trading Engine Cluster
- **Instance Type**: n2-standard-4 (configurable)
- **Auto Scaling**: Managed instance group with health checks
- **Network**: Private subnet with controlled access
- **Storage**: 50GB persistent disk per instance

### Database Configuration
- **Engine**: PostgreSQL 14
- **High Availability**: Regional persistent disks
- **Backup**: Daily automated backups at 3:00 AM UTC
- **Network**: Private IP with VPC peering

### Redis Cache
- **Tier**: Standard HA for high availability
- **Memory**: 4GB (configurable)
- **Network**: Private service access within VPC
- **Version**: Redis 6.X

### Security Features
- VPC isolation with private subnets
- Service accounts with minimal required permissions
- Encrypted storage and transit
- Firewall rules restricting access
- Audit logging enabled

## Monitoring and Maintenance

### Health Checks
- Trading engine instances have HTTP health checks on port 8080
- Unhealthy instances are automatically replaced
- Load balancer performs backend health monitoring

### Backup Strategy
- Database: Daily automated backups with 7-day retention
- Storage: Object versioning enabled for compliance data
- Instance templates: Stored for disaster recovery

### Scaling
- Trading engine: Adjust `trading_engine_instance_count` variable
- Database: Modify `database_tier` for vertical scaling
- Redis: Update `redis_memory_size` for cache scaling

## Cost Optimization

- Use preemptible instances for non-critical workloads
- Implement lifecycle policies for storage buckets
- Monitor resource utilization and adjust sizing
- Consider regional vs. global resources based on requirements

## Security Considerations

- Regularly rotate service account keys
- Monitor access logs and audit trails
- Keep instance images updated with security patches
- Review firewall rules and network access patterns
- Implement proper backup encryption and retention

## Troubleshooting

### Common Issues

1. **Instance Group Not Healthy**
   - Check health check configuration
   - Verify application is listening on correct port
   - Review instance startup scripts

2. **Database Connection Issues**
   - Verify VPC peering configuration
   - Check firewall rules for database access
   - Confirm service account permissions

3. **Load Balancer 502 Errors**
   - Check backend service health
   - Verify instance group is serving traffic
   - Review application logs

### Useful Commands

```bash
# Check instance group status
gcloud compute instance-groups managed describe trading-engine-cluster --zone=us-central1-a

# View database logs
gcloud sql operations list --instance=digital-asset-trading-platform-db-main

# Check Cloud Run service status
gcloud run services describe api-gateway --region=us-central1
```

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources and data. Ensure you have proper backups before proceeding.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Google Cloud Platform documentation
3. Consult Terraform Google provider documentation
4. Contact your infrastructure team or cloud architect