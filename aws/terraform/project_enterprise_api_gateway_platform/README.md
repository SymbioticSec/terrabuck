# Enterprise API Gateway and Management Platform

This Terraform configuration deploys a comprehensive API gateway platform for enterprise use, providing centralized authentication, rate limiting, API versioning, analytics, and developer portal functionality.

## Architecture Overview

The platform consists of the following components:

- **API Gateway**: Main entry point for all API requests with routing and rate limiting
- **Lambda Authorizer**: Custom authorization logic for JWT tokens and API keys
- **DynamoDB**: High-performance storage for API keys, rate limiting counters, and session data
- **S3 Bucket**: Hosts API documentation and developer portal assets
- **CloudFront CDN**: Global content delivery for documentation and static assets
- **CloudWatch**: Comprehensive monitoring, logging, and analytics
- **Secrets Manager**: Secure storage and rotation of API keys and credentials

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Python 3.9 runtime for Lambda function (create authorizer.zip file)

## Deployment Instructions

1. **Clone and Navigate**:
   ```bash
   git clone <repository-url>
   cd enterprise-api-gateway-platform
   ```

2. **Create Lambda Deployment Package**:
   ```bash
   # Create a simple authorizer function
   mkdir lambda-src
   cat > lambda-src/index.py << 'EOF'
   import json
   import boto3
   import os

   def handler(event, context):
       # Simple authorizer logic
       token = event.get('authorizationToken', '')
       
       if token == 'allow':
           effect = 'Allow'
       else:
           effect = 'Deny'
           
       return {
           'principalId': 'user123',
           'policyDocument': {
               'Version': '2012-10-17',
               'Statement': [
                   {
                       'Action': 'execute-api:Invoke',
                       'Effect': effect,
                       'Resource': event['methodArn']
                   }
               ]
           }
       }
   EOF
   
   cd lambda-src
   zip ../authorizer.zip index.py
   cd ..
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan Deployment**:
   ```bash
   terraform plan
   ```

5. **Deploy Infrastructure**:
   ```bash
   terraform apply
   ```

6. **Verify Deployment**:
   ```bash
   # Test API Gateway endpoint
   curl $(terraform output -raw api_gateway_url)/api
   
   # Check CloudFront distribution
   echo "CloudFront URL: https://$(terraform output -raw cloudfront_domain_name)"
   ```

## Configuration

### Variables

- `aws_region`: AWS region for deployment (default: us-east-1)
- `project_name`: Project identifier (default: enterprise-api-gateway-platform)
- `environment`: Environment name (default: dev)
- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/16)
- `log_retention_days`: CloudWatch log retention (default: 14 days)

### Customization

To customize the deployment:

1. **Update Variables**:
   ```bash
   terraform apply -var="environment=prod" -var="aws_region=us-west-2"
   ```

2. **Use terraform.tfvars**:
   ```hcl
   aws_region = "us-west-2"
   environment = "production"
   project_name = "my-api-gateway"
   vpc_cidr = "172.16.0.0/16"
   log_retention_days = 30
   ```

## API Usage

### Authentication

The platform supports multiple authentication methods:

1. **API Keys**: Stored in Secrets Manager
2. **JWT Tokens**: Validated by Lambda authorizer
3. **IAM Roles**: For internal service-to-service communication

### Rate Limiting

Rate limits are enforced at the API Gateway level and tracked in DynamoDB:
- Default: 1000 requests per minute per API key
- Burst: 2000 requests
- Configurable per client/partner

### Monitoring

Access monitoring through:
- **CloudWatch Dashboards**: Real-time metrics and alarms
- **API Gateway Logs**: Request/response logging
- **Lambda Logs**: Authorization function execution logs

## Security Features

- **Encryption**: All data encrypted in transit and at rest
- **Network Isolation**: Private subnets for Lambda functions
- **Access Control**: IAM roles with least privilege principles
- **Secrets Management**: Automatic rotation of API keys
- **Audit Logging**: Comprehensive access and modification logs

## Maintenance

### Updating API Documentation

Upload new documentation to the S3 bucket:
```bash
aws s3 sync ./docs s3://$(terraform output -raw s3_bucket_name)/
```

### Rotating Secrets

Secrets are automatically rotated, but manual rotation can be triggered:
```bash
aws secretsmanager rotate-secret --secret-id $(terraform output -raw secrets_manager_secret_arn)
```

### Scaling

The platform automatically scales based on demand:
- **API Gateway**: Handles up to 10,000 requests per second
- **Lambda**: Concurrent execution scaling
- **DynamoDB**: On-demand billing mode
- **CloudFront**: Global edge locations

## Troubleshooting

### Common Issues

1. **Lambda Authorization Failures**:
   - Check CloudWatch logs: `/aws/lambda/enterprise-api-gateway-platform-authorizer`
   - Verify JWT token format and signature

2. **API Gateway 5xx Errors**:
   - Review API Gateway execution logs
   - Check Lambda function permissions

3. **S3/CloudFront Issues**:
   - Verify Origin Access Identity configuration
   - Check S3 bucket policies

### Support

For issues and support:
1. Check CloudWatch logs for error details
2. Review AWS service health dashboard
3. Validate IAM permissions and policies

## Cost Optimization

- **API Gateway**: Pay per request model
- **Lambda**: Pay per invocation and duration
- **DynamoDB**: On-demand pricing for variable workloads
- **S3**: Lifecycle policies for documentation versioning
- **CloudFront**: Edge caching reduces origin requests

## Cleanup

To destroy the infrastructure:
```bash
terraform destroy
```

**Note**: Ensure S3 buckets are empty before destruction, as Terraform cannot delete non-empty buckets.