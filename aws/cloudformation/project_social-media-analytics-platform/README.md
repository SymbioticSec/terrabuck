# Social Media Analytics Platform - CloudFormation Deployment

## Overview

This CloudFormation template deploys a comprehensive social media analytics platform that collects, processes, and analyzes social media data from multiple sources. The platform provides real-time insights, sentiment analysis, and trend reporting capabilities for marketing teams and brand managers.

## Architecture Components

### Core Services
- **API Gateway**: RESTful API for social media data ingestion with rate limiting
- **Kinesis Streams**: Real-time data streaming and processing pipeline
- **Lambda Functions**: Serverless analytics processing for sentiment analysis and trend detection
- **RDS PostgreSQL**: Metrics database for processed analytics data
- **S3 Bucket**: Data lake for raw social media content and historical archives
- **EC2 Instance**: Dashboard application server with interactive reporting tools

### Network Architecture
- **VPC**: Isolated network environment with public and private subnets
- **Multi-AZ Deployment**: High availability across two availability zones
- **Security Groups**: Layered security controls for each component
- **Internet Gateway**: Public internet access for API and dashboard

## Prerequisites

### AWS Requirements
- AWS CLI configured with appropriate credentials
- CloudFormation permissions for all resource types
- Sufficient service limits for EC2, RDS, and Lambda
- Valid AWS account with billing enabled

### Local Requirements
- AWS CLI version 2.0 or higher
- CloudFormation template validation tools
- SSH key pair for EC2 instance access (optional)

## Deployment Instructions

### Step 1: Parameter Configuration

Create a parameters file `parameters.json`:

```json
[
  {
    "ParameterKey": "Environment",
    "ParameterValue": "production"
  },
  {
    "ParameterKey": "ProjectName",
    "ParameterValue": "social-media-analytics-platform"
  },
  {
    "ParameterKey": "DatabasePassword",
    "ParameterValue": "YourSecurePassword123!"
  },
  {
    "ParameterKey": "DatabaseInstanceClass",
    "ParameterValue": "db.t3.medium"
  },
  {
    "ParameterKey": "InstanceType",
    "ParameterValue": "t3.medium"
  }
]
```

### Step 2: Deploy the Stack

```bash
# Validate the template
aws cloudformation validate-template --template-body file://main.yaml

# Deploy the stack
aws cloudformation create-stack \
  --stack-name social-media-analytics-platform \
  --template-body file://main.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Monitor deployment progress
aws cloudformation describe-stacks \
  --stack-name social-media-analytics-platform \
  --query 'Stacks[0].StackStatus'
```

### Step 3: Verify Deployment

```bash
# Check stack outputs
aws cloudformation describe-stacks \
  --stack-name social-media-analytics-platform \
  --query 'Stacks[0].Outputs'

# Test API Gateway endpoint
curl -X GET "$(aws cloudformation describe-stacks \
  --stack-name social-media-analytics-platform \
  --query 'Stacks[0].Outputs[?OutputKey==`APIGatewayURL`].OutputValue' \
  --output text)/health"
```

## Post-Deployment Configuration

### Database Setup

1. Connect to the RDS instance using the provided endpoint
2. Create necessary tables for analytics data:

```sql
-- Connect to database
psql -h <DATABASE_ENDPOINT> -U analytics_admin -d postgres

-- Create analytics tables
CREATE TABLE social_media_posts (
    id SERIAL PRIMARY KEY,
    platform VARCHAR(50),
    content TEXT,
    sentiment_score DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE campaign_metrics (
    id SERIAL PRIMARY KEY,
    campaign_id VARCHAR(100),
    engagement_rate DECIMAL(5,2),
    reach INTEGER,
    impressions INTEGER,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Lambda Function Configuration

1. Update Lambda environment variables:
   - `DATABASE_HOST`: RDS endpoint from stack outputs
   - `S3_BUCKET`: S3 bucket name from stack outputs
   - `KINESIS_STREAM`: Stream name from stack outputs

2. Deploy application code to Lambda function:

```bash
# Package and deploy Lambda code
zip -r analytics-processor.zip index.py requirements.txt
aws lambda update-function-code \
  --function-name social-media-analytics-platform-analytics-processor \
  --zip-file fileb://analytics-processor.zip
```

### Dashboard Application Setup

1. SSH into the EC2 instance:

```bash
# Get instance public IP from outputs
INSTANCE_IP=$(aws cloudformation describe-stacks \
  --stack-name social-media-analytics-platform \
  --query 'Stacks[0].Outputs[?OutputKey==`DashboardPublicIP`].OutputValue' \
  --output text)

# SSH to instance (requires key pair)
ssh -i your-key.pem ec2-user@$INSTANCE_IP
```

2. Deploy dashboard application:

```bash
# Install application dependencies
sudo yum install -y nodejs npm
git clone https://github.com/your-org/social-media-dashboard.git
cd social-media-dashboard
npm install

# Configure environment variables
export DATABASE_URL="postgresql://analytics_admin:password@<DB_ENDPOINT>:5432/postgres"
export S3_BUCKET="<S3_BUCKET_NAME>"

# Start application
npm start
```

## Security Configuration

### API Gateway Security
- API keys are required for all endpoints
- Rate limiting is configured at 1000 requests per minute
- CORS is enabled for web dashboard integration

### Database Security
- Database is deployed in private subnets
- Security groups restrict access to Lambda and EC2 only
- Encryption at rest is enabled
- Automated backups are configured with 7-day retention

### Network Security
- All resources are deployed in private subnets except dashboard
- Security groups follow least privilege principle
- VPC flow logs can be enabled for network monitoring

## Monitoring and Logging

### CloudWatch Integration
- Lambda functions automatically log to CloudWatch
- RDS performance insights are enabled
- API Gateway access logging is configured

### Custom Metrics
- Set up custom CloudWatch metrics for business KPIs
- Configure alarms for error rates and performance thresholds

## Maintenance and Updates

### Regular Tasks
- Monitor RDS storage usage and scale as needed
- Review Lambda function performance and optimize
- Update security groups and access policies
- Backup and archive S3 data according to retention policies

### Scaling Considerations
- Increase Kinesis shard count for higher throughput
- Scale RDS instance class for larger datasets
- Add Auto Scaling for EC2 dashboard instances
- Implement Lambda reserved concurrency for consistent performance

## Troubleshooting

### Common Issues

1. **Lambda timeout errors**: Increase timeout and memory allocation
2. **Database connection failures**: Check security