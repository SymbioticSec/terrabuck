# Real-Time Trading Platform Infrastructure

This Terraform configuration deploys a complete high-frequency trading platform infrastructure on AWS, designed for a mid-sized investment firm processing thousands of trades per minute.

## Architecture Overview

The platform implements a microservices architecture with the following components:

- **Market Data Ingestion**: Kinesis Data Streams for real-time market data
- **Trade Execution Engine**: High-performance EC2 instances running trading algorithms
- **Trade Database**: PostgreSQL RDS instance for trade history and portfolio data
- **Risk Analytics Processor**: Lambda functions for real-time risk calculations
- **Client Portal API**: Application Load Balancer for client applications
- **Audit Log Storage**: S3 bucket for regulatory compliance and audit trails

## Network Architecture

- **Multi-AZ VPC** with dedicated subnets for different tiers
- **Public DMZ**: Client-facing services behind ALB
- **Private Application Tier**: Trading engines and Lambda functions
- **Private Data Tier**: RDS database with restricted access

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Appropriate IAM permissions for resource creation

## Deployment Instructions

### 1. Clone and Prepare

```bash
git clone <repository>
cd real-time-trading-platform
```

### 2. Create Lambda Deployment Package

```bash
# Create a simple Lambda function for risk calculations
mkdir -p lambda
cat > lambda/index.py << 'EOF'
import json
import os

def handler(event, context):
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Risk calculation completed',
            'db_endpoint': os.environ.get('DB_ENDPOINT'),
            'kinesis_stream': os.environ.get('KINESIS_STREAM')
        })
    }
EOF

cd lambda
zip ../risk_calculator.zip index.py
cd ..
```

### 3. Create User Data Script

```bash
cat > user_data.sh << 'EOF'
#!/bin/bash
apt-get update
apt-get install -y python3 python3-pip postgresql-client
pip3 install boto3 psycopg2-binary

# Configure trading engine service
cat > /opt/trading_engine.py << 'PYTHON'
import boto3
import psycopg2
import time

def main():
    print("Trading engine starting...")
    # Connect to database: ${db_endpoint}
    while True:
        print("Processing trades...")
        time.sleep(10)

if __name__ == "__main__":
    main()
PYTHON

# Start trading engine
nohup python3 /opt/trading_engine.py &
EOF
```

### 4. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 5. Configure Database Password

You'll be prompted for the database password during deployment:

```bash
terraform apply -var="db_password=YourSecurePassword123!"
```

## Post-Deployment Configuration

### 1. Database Setup

```bash
# Connect to the RDS instance
DB_ENDPOINT=$(terraform output -raw database_endpoint)
psql -h $DB_ENDPOINT -U trading_admin -d trading_platform

# Create trading tables
CREATE TABLE trades (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(10),
    quantity INTEGER,
    price DECIMAL(10,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE portfolios (
    id SERIAL PRIMARY KEY,
    client_id VARCHAR(50),
    symbol VARCHAR(10),
    position INTEGER,
    avg_cost DECIMAL(10,2)
);
```

### 2. Kinesis Stream Configuration

```bash
# Test Kinesis stream
aws kinesis put-record \
    --stream-name $(terraform output -raw kinesis_stream_name) \
    --data '{"symbol":"AAPL","price":150.25,"volume":1000}' \
    --partition-key "AAPL"
```

### 3. Load Balancer Health Checks

Configure target groups and health checks for the trading engine instances through the AWS console.

## Monitoring and Maintenance

### CloudWatch Logs

- Lambda function logs: `/aws/lambda/real-time-trading-platform-lambda-risk-calculator`
- EC2 instance logs: Configure CloudWatch agent on trading engines

### Security Considerations

- All database connections use encryption in transit
- S3 audit logs have versioning enabled
- KMS encryption for sensitive data
- Security groups follow least-privilege principles

### Backup and Recovery

- RDS automated backups configured
- S3 audit logs with cross-region replication recommended
- Regular snapshots of trading engine configurations

## Cost Optimization

- Consider using Spot instances for non-critical workloads
- Implement lifecycle policies for S3 audit logs
- Monitor CloudWatch costs and adjust retention periods

## Compliance Features

- CloudTrail logging for all API calls
- S3 audit logs for regulatory requirements
- Encrypted storage for all sensitive data
- Network isolation between tiers

## Troubleshooting

### Common Issues

1. **Database Connection Failures**
   - Check security group rules
   - Verify subnet routing
   - Confirm database credentials

2. **Lambda Function Timeouts**
   - Increase timeout values
   - Check VPC configuration
   - Monitor CloudWatch logs

3. **Load Balancer Health Check Failures**
   - Verify target group configuration
   - Check EC2 instance health
   - Review security group rules

### Support Contacts

- Infrastructure Team: infrastructure@tradingfirm.com
- Database Team: dba@tradingfirm.com
- Security Team: security@tradingfirm.com

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources and data. Ensure backups are taken before destruction.