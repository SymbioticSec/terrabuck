# Global Content Delivery Platform

A scalable content delivery platform for a media company that serves video content, images, and documents to global audiences. The platform includes content upload processing, global distribution via CDN, user authentication, and analytics tracking.

## Architecture Overview

This Terraform configuration deploys a complete content delivery platform with the following components:

- **Content Storage**: S3 buckets for original and processed content
- **Content Processing**: Lambda functions for image resizing and video transcoding
- **Global CDN**: CloudFront distribution for fast content delivery
- **User Database**: PostgreSQL RDS instance for user accounts and metadata
- **API Gateway**: RESTful API for content management and authentication
- **Backend Services**: ECS Fargate services for application logic
- **Networking**: Multi-AZ VPC with public and private subnets

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Docker (for building container images)

## Deployment Instructions

1. **Clone and Navigate**
   ```bash
   git clone <repository-url>
   cd global-content-delivery-platform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Create Lambda Deployment Package**
   ```bash
   echo 'def handler(event, context): return {"statusCode": 200}' > lambda_function.py
   zip content_processing.zip lambda_function.py
   ```

4. **Review and Customize Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your desired values
   ```

5. **Plan Deployment**
   ```bash
   terraform plan
   ```

6. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-east-1` |
| `project_name` | Project name for resource naming | `global-content-delivery-platform` |
| `environment` | Environment name | `production` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `db_instance_class` | RDS instance type | `db.t3.micro` |
| `db_username` | Database username | `contentadmin` |
| `db_password` | Database password | `changeme123!` |

## Post-Deployment Steps

1. **Build and Push Container Images**
   ```bash
   # Get ECR login token
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
   
   # Build and push your application image
   docker build -t backend-services .
   docker tag backend-services:latest <ecr-repository-url>:latest
   docker push <ecr-repository-url>:latest
   ```

2. **Configure API Gateway**
   - Add resources and methods to the API Gateway
   - Configure integration with Lambda functions and ECS services
   - Deploy API changes

3. **Set up Content Processing Triggers**
   - Configure S3 event notifications to trigger Lambda functions
   - Set up processing workflows for different content types

## Security Considerations

- Change default database password before deployment
- Configure proper IAM policies with least privilege access
- Enable VPC Flow Logs for network monitoring
- Set up CloudWatch alarms for security monitoring
- Configure WAF rules for API Gateway protection

## Monitoring and Logging

- CloudWatch logs are configured for ECS services
- Enable VPC Flow Logs for network traffic analysis
- Set up CloudWatch alarms for key metrics
- Configure SNS notifications for alerts

## Cost Optimization

- S3 lifecycle policies for content archival
- CloudFront caching to reduce origin requests
- Auto Scaling for ECS services based on demand
- Reserved instances for predictable workloads

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Support

For issues and questions, please refer to the project documentation or contact the infrastructure team.