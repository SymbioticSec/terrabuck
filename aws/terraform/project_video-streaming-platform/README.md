# Corporate Training Video Streaming Platform

This Terraform configuration deploys a complete serverless video streaming platform for corporate training content with user authentication, video transcoding, CDN delivery, and analytics.

## Architecture Overview

The platform consists of the following components:

- **Video Storage**: S3 buckets for storing original and transcoded video files
- **Content Delivery**: CloudFront CDN for global video delivery
- **User Management**: Cognito User Pool for authentication and authorization
- **API Gateway**: RESTful API for video metadata and user progress
- **Database**: DynamoDB for storing video metadata and user progress
- **Processing**: Lambda functions for video processing and analytics
- **Monitoring**: CloudWatch logs and CloudTrail for audit logging

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- A registered domain name for API Gateway custom domain

## Deployment Instructions

1. **Clone the repository and navigate to the project directory**

2. **Create a Lambda deployment package**:
   ```bash
   echo 'def handler(event, context): return {"statusCode": 200, "body": "Hello World"}' > index.py
   zip video_processing.zip index.py
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review and modify variables** (optional):
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

5. **Plan the deployment**:
   ```bash
   terraform plan
   ```

6. **Apply the configuration**:
   ```bash
   terraform apply
   ```

7. **Note the outputs** for integration with your applications

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | `us-east-1` |
| `project_name` | Name of the project | `corporate-training-video-streaming-platform` |
| `environment` | Environment name | `production` |
| `domain_name` | Domain name for the API | `example.com` |

## Security Features

- S3 bucket encryption and versioning enabled
- CloudFront with Origin Access Identity
- Cognito User Pool with password policies
- API Gateway with Cognito authorization
- IAM roles with least privilege access
- CloudTrail for audit logging
- DynamoDB encryption at rest

## Usage

After deployment, you can:

1. **Create users** in the Cognito User Pool
2. **Upload videos** to the S3 bucket
3. **Access videos** through the CloudFront distribution
4. **Use the API** to manage video metadata and track user progress
5. **Monitor activity** through CloudWatch logs and CloudTrail

## Monitoring and Logging

- CloudWatch logs capture Lambda function execution
- CloudTrail logs all API calls for audit purposes
- API Gateway provides request/response logging
- DynamoDB metrics available in CloudWatch

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Support

For issues or questions, please refer to the AWS documentation for each service or contact your system administrator.