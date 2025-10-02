# Fleet Management GPS Tracking System

A comprehensive fleet management platform for logistics companies to track vehicle locations, monitor driver behavior, manage maintenance schedules, and optimize delivery routes.

## Architecture Overview

This Terraform configuration deploys a complete fleet management system with the following components:

- **GPS Data Ingestion**: API Gateway endpoints for receiving GPS data from vehicle IoT devices
- **Telemetry Processor**: Lambda function for processing GPS data and detecting violations
- **Vehicle Database**: PostgreSQL RDS instance storing vehicle profiles and driver information
- **Tracking Data Storage**: S3 bucket for archiving raw GPS tracking data
- **Fleet Dashboard**: EC2-hosted web application for real-time fleet monitoring
- **Alert Notification**: SNS topic for emergency and maintenance alerts

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Python 3.9 runtime for Lambda functions

## Deployment Instructions

1. **Clone and Navigate**
   ```bash
   git clone <repository-url>
   cd fleet-management-gps-tracker
   ```

2. **Create Lambda Deployment Package**
   ```bash
   # Create a simple Lambda function package
   mkdir lambda_package
   cd lambda_package
   echo 'def handler(event, context): return {"statusCode": 200, "body": "GPS data received"}' > index.py
   zip ../telemetry_processor.zip index.py
   cd ..
   ```

3. **Create Dashboard User Data Script**
   ```bash
   cat > dashboard_userdata.sh << 'EOF'
   #!/bin/bash
   apt-get update
   apt-get install -y nginx python3 python3-pip
   pip3 install flask psycopg2-binary boto3
   systemctl start nginx
   systemctl enable nginx
   # Additional dashboard setup would go here
   EOF
   ```

4. **Initialize Terraform**
   ```bash
   terraform init
   ```

5. **Plan Deployment**
   ```bash
   terraform plan
   ```

6. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

7. **Configure API Gateway Deployment**
   After initial deployment, you'll need to deploy the API Gateway:
   ```bash
   aws apigateway create-deployment \
     --rest-api-id $(terraform output -raw api_gateway_url | cut -d'/' -f3 | cut -d'.' -f1) \
     --stage-name prod
   ```

## Configuration

### Environment Variables

Set the following variables in `terraform.tfvars`:

```hcl
aws_region = "us-east-1"
environment = "production"
db_password = "YourSecurePassword123!"
dashboard_instance_type = "t3.small"
```

### Database Setup

After deployment, connect to the RDS instance and run initial schema setup:

```sql
CREATE TABLE vehicles (
    id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(50) UNIQUE,
    make VARCHAR(50),
    model VARCHAR(50),
    year INTEGER,
    license_plate VARCHAR(20)
);

CREATE TABLE gps_data (
    id SERIAL PRIMARY KEY,
    vehicle_id VARCHAR(50),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    speed DECIMAL(5,2),
    timestamp TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
);
```

## Usage

### GPS Data Ingestion

Send GPS data to the API Gateway endpoint:

```bash
curl -X POST https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/gps-data \
  -H "Content-Type: application/json" \
  -d '{
    "vehicle_id": "TRUCK001",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "speed": 45.5,
    "timestamp": "2024-01-15T10:30:00Z"
  }'
```

### Dashboard Access

Access the fleet dashboard at: `http://<dashboard-public-ip>`

### Monitoring

- CloudWatch logs for Lambda functions: `/aws/lambda/fleet-management-gps-tracking-system-lambda-telemetry-processor`
- CloudTrail logs in S3 bucket: `fleet-management-gps-tracking-system-cloudtrail-*`

## Security Considerations

This deployment includes several security configurations:
- VPC with public/private subnet isolation
- Security groups with restricted access
- IAM roles with least privilege principles
- CloudTrail for audit logging
- Password policies for user accounts

## Scaling

To handle increased load:
- Increase Lambda concurrent executions
- Scale RDS instance class
- Add Application Load Balancer for dashboard
- Implement S3 lifecycle policies for data archival

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Support

For issues or questions, please refer to the AWS documentation or contact the infrastructure team.