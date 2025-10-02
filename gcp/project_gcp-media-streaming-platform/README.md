# Media Streaming Platform Infrastructure

This Terraform configuration deploys a complete media streaming platform on Google Cloud Platform with content delivery capabilities.

## Architecture Overview

The platform includes:
- **Content Storage**: Google Cloud Storage buckets for original and transcoded video content
- **Transcoding Service**: Cloud Function for automated video processing
- **Streaming API**: Compute Engine instance running RESTful API service
- **User Database**: Cloud SQL PostgreSQL for user accounts and metadata
- **CDN Distribution**: Global content delivery network with HTTPS
- **Analytics Pipeline**: Pub/Sub for real-time event streaming

## Prerequisites

1. Google Cloud Platform account with billing enabled
2. Terraform >= 1.0 installed
3. Google Cloud SDK installed and authenticated
4. Required APIs enabled:
   - Compute Engine API
   - Cloud SQL API
   - Cloud Storage API
   - Cloud Functions API
   - Pub/Sub API
   - Service Networking API

## Deployment Instructions

### 1. Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

### 2. Set Up Variables

Create a `terraform.tfvars` file:

```hcl
project_id     = "your-gcp-project-id"
project_number = "your-gcp-project-number"
region         = "us-central1"
zone           = "us-central1-a"
db_password    = "your-secure-database-password"
domain_name    = "your-domain.com"
```

### 3. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 4. Post-Deployment Configuration

1. **DNS Configuration**: Point your domain to the CDN global IP address
2. **Database Setup**: Connect to the database and create necessary tables
3. **Content Upload**: Upload initial video content to the content storage bucket
4. **API Testing**: Verify the streaming API is responding at the external IP

## Resource Overview

| Component | Resource Type | Purpose |
|-----------|---------------|---------|
| Content Storage | Cloud Storage | Original video files and metadata |
| Transcoded Storage | Cloud Storage | Processed video variants |
| Transcoding Service | Cloud Function | Automated video processing |
| Streaming API | Compute Engine | RESTful API for content delivery |
| User Database | Cloud SQL | User accounts and viewing data |
| CDN Distribution | Global Forwarding Rule | Low-latency content delivery |
| Analytics Pipeline | Pub/Sub | Real-time event streaming |

## Security Features

- VPC network isolation with public and private subnets
- Cloud SQL with private IP configuration
- Managed SSL certificates for HTTPS
- IAM service accounts for component authentication
- Storage bucket lifecycle management
- Firewall rules for network access control

## Monitoring and Analytics

- Pub/Sub topic for streaming analytics events
- Cloud Function logs for transcoding operations
- Compute Engine monitoring for API performance
- Cloud SQL monitoring for database metrics

## Scaling Considerations

- **Horizontal Scaling**: Add more API instances behind a load balancer
- **Storage Scaling**: Implement bucket sharding for high-volume content
- **Database Scaling**: Configure read replicas for improved performance
- **CDN Scaling**: Leverage global edge locations automatically

## Cost Optimization

- Lifecycle policies for storage cost reduction
- Preemptible instances for non-critical workloads
- Cloud Function pay-per-use model
- CDN caching to reduce origin requests

## Troubleshooting

### Common Issues

1. **SSL Certificate Provisioning**: May take 10-60 minutes for domain validation
2. **Database Connectivity**: Ensure private VPC connection is established
3. **Function Deployment**: Check source code archive and dependencies
4. **Firewall Rules**: Verify network access for API endpoints

### Useful Commands

```bash
# Check resource status
terraform show

# View outputs
terraform output

# Destroy infrastructure
terraform destroy
```

## Support

For issues and questions:
1. Check Terraform plan output for configuration errors
2. Review Google Cloud Console for resource status
3. Examine Cloud Function logs for transcoding issues
4. Monitor Cloud SQL for database connectivity

## License

This infrastructure code is provided as-is for educational and development purposes.