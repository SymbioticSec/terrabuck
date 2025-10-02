# Real-Time Event Streaming Analytics Platform

A comprehensive AWS CloudFormation template for deploying a scalable event streaming platform that processes and analyzes real-time user behavior data from mobile applications and web platforms.

## Architecture Overview

This platform implements an event-driven microservices architecture with the following components:

- **Event Ingestion Gateway**: API Gateway for receiving events from client applications
- **Event Stream Processor**: Kinesis Data Streams for real-time event buffering
- **Real-time Analytics Engine**: Lambda functions for processing streaming events
- **Metrics Cache Layer**: ElastiCache Redis for fast dashboard data access
- **Historical Data Warehouse**: RDS PostgreSQL for long-term analytics storage
- **Raw Event Archive**: S3 bucket for compliance and reprocessing needs

## Prerequisites

- AWS CLI configured with appropriate permissions
- AWS account with sufficient service limits
- CloudFormation deployment permissions

## Required IAM Permissions

The deploying user/role needs the following permissions:
- CloudFormation full access
- EC2, VPC, and networking permissions
- IAM role creation and policy attachment
- API Gateway, Lambda, Kinesis permissions
- RDS, ElastiCache, and S3 permissions

## Deployment Instructions

### 1. Clone and Prepare

```bash
git clone <repository-url>
cd real-time-event-streaming-platform
```

### 2. Configure Parameters

Edit the `variables.yaml` file to customize your deployment:

```yaml
Environment: production
ProjectName: real-time-event-streaming-analytics-platform
VpcCidr: 10.0.0.0/16
DatabaseUsername: analytics_admin
DatabasePassword: YourSecurePassword123!
DatabaseInstanceClass: db.t3.medium
```

### 3. Deploy the Stack

```bash
aws cloudformation create-stack \
  --stack-name event-streaming-platform \
  --template-body file://main.yaml \
  --parameters ParameterKey=Environment,ParameterValue=production \
               ParameterKey=DatabasePassword,ParameterValue=YourSecurePassword123! \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### 4. Monitor Deployment

```bash
aws cloudformation describe-stacks \
  --stack-name event-streaming-platform \
  --query 'Stacks[0].StackStatus'
```

### 5. Retrieve Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name event-streaming-platform \
  --query 'Stacks[0].Outputs'
```

## Configuration Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| Environment | Deployment environment | production | Yes |
| ProjectName | Project name for resources | real-time-event-streaming-analytics-platform | Yes |
| VpcCidr | VPC CIDR block | 10.0.0.0/16 | Yes |
| DatabaseUsername | RDS master username | analytics_admin | Yes |
| DatabasePassword | RDS master password | - | Yes |
| DatabaseInstanceClass | RDS instance type | db.t3.medium | Yes |

## Post-Deployment Configuration

### 1. API Gateway Deployment

After stack creation, deploy the API Gateway stage:

```bash
aws apigateway create-deployment \
  --rest-api-id <API_GATEWAY_ID> \
  --stage-name prod
```

### 2. Database Schema Setup

Connect to the PostgreSQL database and create the analytics schema:

```sql
CREATE DATABASE analytics;
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255),
    event_type VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    properties JSONB
);
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_timestamp ON events(timestamp);
```

### 3. Lambda Function Updates

Update the Lambda function code for your specific analytics requirements:

```python
import json
import boto3
import psycopg2
import redis

def handler(event, context):
    # Your custom analytics logic here
    pass
```

## Usage Examples

### Sending Events to API Gateway

```bash
curl -X POST https://<API_GATEWAY_URL>/events \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "eventType": "page_view",
    "properties": {
      "page": "/dashboard",
      "timestamp": "2023-12-01T10:00:00Z"
    }
  }'
```

### Querying Analytics Data

```python
import psycopg2

conn = psycopg2.connect(
    host="<DATABASE_ENDPOINT>",
    database="analytics",
    user="analytics_admin",
    password="<PASSWORD>"
)

cursor = conn.cursor()
cursor.execute("""
    SELECT event_type, COUNT(*) 
    FROM events 
    WHERE timestamp >= NOW() - INTERVAL '1 hour'
    GROUP BY event_type
""")
results = cursor.fetchall()
```

## Monitoring and Maintenance

### CloudWatch Metrics

Monitor the following key metrics:
- API Gateway request count and latency
- Kinesis incoming records and iterator age
- Lambda function duration and error rate
- RDS CPU utilization and connections
- ElastiCache hit ratio and memory usage

### Scaling Considerations

- **Kinesis**: Increase shard count for higher throughput
- **Lambda**: Adjust memory and timeout settings
- **RDS**: Scale up instance class or enable read replicas
- **ElastiCache**: Add more nodes to the cluster

### Backup and Recovery

- RDS automated backups are enabled (7 days retention in production)
- S3 versioning is enabled for event archive
- Consider cross-region replication for disaster recovery

## Cost Optimization

- S3 lifecycle policies automatically transition old data to cheaper storage classes
- Use reserved instances for RDS in production
- Monitor and adjust Kinesis shard count based on usage
- Implement Lambda provisioned concurrency only if needed

## Security Considerations

- All data is encrypted in transit and at rest
- VPC isolation with private subnets for data stores
- IAM roles follow principle of least privilege
- API Gateway uses AWS IAM authentication
- Security groups restrict access between components

## Troubleshooting

### Common Issues

1. **Stack Creation Fails**: Check IAM permissions and service limits
2. **Lambda Timeout**: Increase timeout or optimize function code
3. **Database Connection Issues**: Verify security group rules
4. **API Gateway 5xx Errors**: Check Lambda function logs

### Useful Commands

```bash
# View CloudFormation events
aws cloudformation describe-stack-events --stack-name event-streaming-platform

# Check Lambda logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/

# Monitor Kinesis metrics
aws kinesis describe-stream --stream-name <STREAM_NAME>
```

## Cleanup

To delete all resources:

```bash
aws cloudformation delete-stack --stack-name event-streaming-platform
```

**Note**: Ensure S3 bucket is empty before deletion, as versioned buckets with objects cannot be automatically deleted.

## Support

For issues and questions:
- Check AWS CloudFormation documentation
- Review CloudWatch logs for component-specific issues
- Consult AWS service-specific troubleshooting guides

## License

This template is provided as-is for educational and production use. Ensure compliance with your organization's security and governance policies before deployment.