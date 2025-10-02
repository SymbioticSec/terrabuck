# Enterprise Video Streaming Platform

A comprehensive AWS CloudFormation template for deploying a scalable enterprise video streaming platform with video upload, transcoding, content delivery, and user management capabilities.

## Architecture Overview

This template deploys a complete video streaming infrastructure including:

- **Video Storage**: S3 bucket with lifecycle policies for raw and transcoded videos
- **Content Delivery**: CloudFront CDN for global video distribution
- **Video Processing**: Lambda function for serverless video transcoding
- **User Management**: EC2-based authentication service with LDAP integration
- **API Gateway**: RESTful API for video metadata and user management
- **Database**: PostgreSQL RDS instance for metadata and user profiles
- **Caching**: ElastiCache Redis for session and metadata caching
- **Monitoring**: CloudTrail for audit logging

## Prerequisites

- AWS CLI configured with appropriate permissions
- CloudFormation deployment permissions
- VPC and networking permissions
- S3, RDS, EC2, Lambda, and API Gateway permissions

## Deployment Instructions

### 1. Clone and Prepare

```bash
git clone <repository-url>
cd enterprise-video-streaming-platform
```

### 2. Deploy the Stack

```bash
aws cloudformation create-stack \
  --stack-name enterprise-video-streaming-platform \
  --template-body file://main.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=DBPassword,ParameterValue=YourSecurePassword123! \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### 3. Monitor Deployment

```bash
aws cloudformation describe-stacks \
  --stack-name enterprise-video-streaming-platform \
  --query 'Stacks[0].StackStatus'
```

### 4. Get Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name enterprise-video-streaming-platform \
  --query 'Stacks[0].Outputs'
```

## Configuration Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| Environment | Deployment environment | production | Yes |
| ProjectName | Project name for resource naming | enterprise-video-streaming-platform | Yes |
| DBUsername | Database master username | videoplatform | Yes |
| DBPassword | Database master password | - | Yes |
| DBInstanceClass | RDS instance class | db.t3.micro | No |
| VpcCidr | VPC CIDR block | 10.0.0.0/16 | No |

## Post-Deployment Configuration

### 1. Configure Video Processing

The Lambda function needs additional configuration for video transcoding:

```bash
# Update Lambda function with video processing libraries
aws lambda update-function-code \
  --function-name enterprise-video-streaming-platform-video-processing \
  --zip-file fileb://video-processing.zip
```

### 2. Configure User Management Service

SSH into the EC2 instance and configure the authentication service:

```bash
# Get instance IP from outputs
INSTANCE_ID=$(aws cloudformation describe-stacks \
  --stack-name enterprise-video-streaming-platform \
  --query 'Stacks[0].Outputs[?OutputKey==`UserManagementInstanceId`].OutputValue' \
  --output text)

# Configure LDAP integration
ssh ec2-user@<instance-ip>
sudo docker run -d -p 8080:8080 video-auth-service
```

### 3. Upload Test Content

```bash
# Get bucket name from outputs
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name enterprise-video-streaming-platform \
  --query 'Stacks[0].Outputs[?OutputKey==`VideoStorageBucketName`].OutputValue' \
  --output text)

# Upload test video
aws s3 cp test-video.mp4 s3://$BUCKET_NAME/raw/
```

## API Usage

### Video Upload Endpoint

```bash
curl -X POST https://<api-gateway-url>/prod/videos \
  -H "Content-Type: application/json" \
  -d '{"title": "Training Video", "description": "Employee onboarding"}'
```

### Video Streaming

Access videos through CloudFront distribution:
```
https://<cloudfront-domain>/processed/video-id/playlist.m3u8
```

## Monitoring and Logging

- **CloudTrail**: Audit logs available in CloudWatch Logs
- **Lambda Logs**: Video processing logs in CloudWatch
- **API Gateway**: Request logs and metrics in CloudWatch
- **RDS**: Database performance metrics in CloudWatch

## Security Features

- VPC with public/private subnet isolation
- Security groups with least-privilege access
- S3 bucket encryption at rest
- RDS encryption at rest
- IAM roles with minimal permissions
- CloudTrail audit logging

## Scaling Considerations

- **Auto Scaling**: Add Auto Scaling Groups for EC2 instances
- **Multi-AZ**: Enable Multi-AZ for RDS in production
- **Lambda Concurrency**: Configure reserved concurrency for video processing
- **CloudFront**: Optimize cache behaviors for video content

## Cost Optimization

- S3 lifecycle policies transition old content to cheaper storage classes
- Use Spot instances for non-critical workloads
- Configure CloudFront caching to reduce origin requests
- Monitor and right-size RDS and EC2 instances

## Troubleshooting

### Common Issues

1. **Stack Creation Fails**
   - Check IAM permissions
   - Verify parameter values
   - Check resource limits in the region

2. **Video Processing Fails**
   - Check Lambda function logs
   - Verify S3 permissions
   - Check Lambda timeout settings

3. **Database Connection Issues**
   - Verify security group rules
   - Check VPC configuration
   - Validate database credentials

### Support

For issues and support:
- Check CloudFormation events for detailed error messages
- Review CloudWatch logs for application errors
- Verify AWS service limits and quotas

## Cleanup

To delete the entire infrastructure:

```bash
aws cloudformation delete-stack \
  --stack-name enterprise-video-streaming-platform
```

**Note**: Ensure S3 buckets are empty before deletion, as CloudFormation cannot delete non-empty buckets.