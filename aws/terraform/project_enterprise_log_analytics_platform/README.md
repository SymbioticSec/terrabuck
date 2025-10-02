# Enterprise Log Analytics and Monitoring Platform

This Terraform configuration deploys a comprehensive log analytics platform on AWS that collects, processes, and analyzes application logs from multiple enterprise systems.

## Architecture Overview

The platform consists of the following components:

1. **API Gateway** - RESTful endpoint for log ingestion
2. **Lambda Function** - Serverless log processing pipeline
3. **S3 Bucket** - Long-term storage for processed logs
4. **Elasticsearch Domain** - Real-time log search and analysis
5. **SNS Topic** - Alert notification system
6. **EC2 Instance** - Dashboard server hosting Kibana

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Python 3.9 runtime for Lambda function

## Deployment Instructions

1. **Clone the repository and navigate to the directory**
   ```bash
   git clone <repository-url>
   cd enterprise-log-analytics-platform
   ```

2. **Create the Lambda deployment package**
   ```bash
   # Create a simple log processor function
   mkdir lambda_package
   cat > lambda_package/index.py << 'EOF'
   import json
   import boto3
   import os
   from datetime import datetime

   def handler(event, context):
       # Process incoming log data
       try:
           body = json.loads(event['body'])
           
           # Add timestamp and processing metadata
           processed_log = {
               'timestamp': datetime.utcnow().isoformat(),
               'original_data': body,
               'processed_by': 'enterprise-log-processor'
           }
           
           # Store in S3
           s3 = boto3.client('s3')
           bucket = os.environ['S3_BUCKET']
           key = f"logs/{datetime.utcnow().strftime('%Y/%m/%d')}/{context.aws_request_id}.json"
           
           s3.put_object(
               Bucket=bucket,
               Key=key,
               Body=json.dumps(processed_log),
               ContentType='application/json'
           )
           
           return {
               'statusCode': 200,
               'body': json.dumps({'message': 'Log processed successfully'})
           }
           
       except Exception as e:
           return {
               'statusCode': 500,
               'body': json.dumps({'error': str(e)})
           }
   EOF

   cd lambda_package
   zip ../log_processor.zip index.py
   cd ..
   ```

3. **Create dashboard user data script**
   ```bash
   cat > dashboard_userdata.sh << 'EOF'
   #!/bin/bash
   apt-get update
   apt-get install -y nginx docker.io
   systemctl start docker
   systemctl enable docker

   # Install Kibana via Docker
   docker run -d \
     --name kibana \
     --restart unless-stopped \
     -p 5601:5601 \
     -e ELASTICSEARCH_HOSTS=https://${elasticsearch_endpoint} \
     docker.elastic.co/kibana/kibana:7.10.3

   # Configure nginx proxy
   cat > /etc/nginx/sites-available/default << 'NGINX_EOF'
   server {
       listen 80 default_server;
       location / {
           proxy_pass http://localhost:5601;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   NGINX_EOF

   systemctl restart nginx
   EOF
   ```

4. **Initialize and deploy Terraform**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Configure variables (optional)**
   Create a `terraform.tfvars` file to customize deployment:
   ```hcl
   aws_region = "us-east-1"
   environment = "production"
   alert_email = "your-email@company.com"
   elasticsearch_instance_type = "t3.medium.elasticsearch"
   dashboard_instance_type = "t3.large"
   ```

## Usage

### Sending Logs to the Platform

Use the API Gateway endpoint to send logs:

```bash
# Get the API endpoint from Terraform output
API_ENDPOINT=$(terraform output -raw api_gateway_url)

# Send a log entry
curl -X POST $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{
    "application": "web-server",
    "level": "INFO",
    "message": "User login successful",
    "timestamp": "2024-01-15T10:30:00Z",
    "user_id": "user123"
  }'
```

### Accessing the Dashboard

1. Get the dashboard instance private IP from Terraform output
2. Set up a bastion host or VPN to access the private subnet
3. Navigate to `http://<dashboard-private-ip>` to access Kibana

### Setting Up Alerts

The SNS topic is configured to send email alerts. Subscribe additional endpoints:

```bash
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol email \
  --notification-endpoint your-email@company.com
```

## Monitoring and Maintenance

- **CloudWatch Logs**: Lambda execution logs are available in CloudWatch
- **S3 Lifecycle**: Logs automatically transition to cheaper storage classes
- **Elasticsearch**: Monitor cluster health via AWS console
- **API Gateway**: Monitor request metrics and errors

## Security Considerations

This deployment includes several security features:
- VPC isolation with private subnets for sensitive components
- Security groups with least-privilege access
- IAM roles with minimal required permissions
- S3 bucket versioning and lifecycle policies
- Elasticsearch cluster in private subnet

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Lambda timeout errors**: Increase timeout in the Lambda configuration
2. **Elasticsearch access denied**: Check VPC security groups and IAM policies
3. **API Gateway 5xx errors**: Check Lambda function logs in CloudWatch
4. **Dashboard not accessible**: Verify security group rules and instance status

### Logs and Debugging

- Lambda logs: CloudWatch Logs `/aws/lambda/enterprise-log-analytics-*`
- API Gateway logs: CloudWatch Logs `/aws/apigateway/enterprise-log-analytics`
- EC2 instance logs: SSH to instance and check `/var/log/cloud-init-output.log`

## Cost Optimization

- Use appropriate instance sizes for your workload
- Configure S3 lifecycle policies to move old logs to cheaper storage
- Set up CloudWatch alarms for cost monitoring
- Consider using Reserved Instances for long-running components

## Support

For issues and questions:
1. Check CloudWatch logs for error messages
2. Verify AWS service limits and quotas
3. Review IAM permissions for all components
4. Ensure all dependencies are properly configured