# Smart City Parking Management System

A comprehensive IoT-enabled parking management system for municipal governments to monitor real-time parking availability, process payments, and optimize traffic flow.

## Architecture Overview

This Terraform configuration deploys a complete smart parking management system with the following components:

- **IoT Data Ingestion**: AWS IoT Core for receiving real-time sensor data
- **Sensor Data Processing**: Lambda functions for processing parking sensor data
- **Parking Database**: PostgreSQL RDS instance for storing parking and payment data
- **Citizen Mobile API**: API Gateway for mobile application endpoints
- **Payment Processing**: Lambda functions for handling payment transactions
- **Admin Dashboard Hosting**: S3 bucket with CloudFront for administrative interface

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Domain name for admin dashboard (optional)

## Deployment Instructions

1. **Clone and Navigate**
   ```bash
   git clone <repository-url>
   cd smart-parking-terraform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Create Lambda Deployment Packages**
   ```bash
   # Create placeholder Lambda packages
   echo 'def handler(event, context): return {"statusCode": 200}' > sensor_processing.py
   zip sensor_processing.zip sensor_processing.py
   
   echo 'def handler(event, context): return {"statusCode": 200}' > payment_processing.py
   zip payment_processing.zip payment_processing.py
   ```

4. **Review and Customize Variables**
   ```bash
   # Copy and modify terraform.tfvars.example
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

5. **Plan Deployment**
   ```bash
   terraform plan
   ```

6. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

## Configuration

### Key Variables

- `aws_region`: AWS region for deployment (default: us-west-2)
- `environment`: Environment name (dev/staging/prod)
- `db_password`: Database master password (change from default)
- `domain_name`: Domain for admin dashboard

### Network Architecture

- VPC with public and private subnets across 2 AZs
- Public subnets for API Gateway and internet-facing resources
- Private subnets for Lambda functions and RDS database
- Security groups with least-privilege access

## Components

### IoT Data Ingestion
- AWS IoT Core thing types and policies
- MQTT communication for sensor data
- Device authentication and certificate management

### Data Processing
- Lambda functions for sensor data validation
- Real-time processing of occupancy status
- Integration with parking database

### Database
- PostgreSQL RDS instance with encryption
- Multi-AZ deployment for high availability
- Automated backups and maintenance windows

### API Gateway
- RESTful endpoints for mobile applications
- Regional deployment for low latency
- Integration with Lambda functions

### Admin Dashboard
- S3 static website hosting
- CloudFront CDN for global distribution
- SSL/TLS encryption for secure access

## Security Features

- VPC isolation with private subnets
- Security groups with specific port access
- RDS encryption at rest
- CloudTrail audit logging
- IAM roles with least privilege

## Monitoring and Logging

- CloudWatch logs for Lambda functions
- CloudTrail for API audit trails
- RDS performance insights
- API Gateway access logging

## Post-Deployment Steps

1. **Upload Admin Dashboard Files**
   ```bash
   aws s3 sync ./admin-dashboard/ s3://$(terraform output -raw admin_dashboard_bucket)/
   ```

2. **Configure IoT Devices**
   - Create IoT certificates
   - Attach policies to certificates
   - Configure MQTT endpoints

3. **Set Up API Gateway Methods**
   - Create REST API resources and methods
   - Configure Lambda integrations
   - Deploy API changes

4. **Database Initialization**
   ```bash
   # Connect to RDS and create tables
   psql -h $(terraform output -raw rds_endpoint) -U parking_admin -d parking_mgmt
   ```

## Maintenance

### Regular Tasks
- Monitor CloudWatch logs and metrics
- Review security group rules
- Update Lambda function code
- Backup database regularly

### Scaling Considerations
- Increase RDS instance size for higher loads
- Add Lambda concurrency limits
- Configure API Gateway throttling
- Use RDS read replicas for read-heavy workloads

## Troubleshooting

### Common Issues

1. **Lambda VPC Connectivity**
   - Ensure NAT Gateway for internet access
   - Verify security group rules

2. **RDS Connection Issues**
   - Check security group ingress rules
   - Verify subnet group configuration

3. **API Gateway 5xx Errors**
   - Check Lambda function logs
   - Verify IAM permissions

### Useful Commands

```bash
# View Lambda logs
aws logs tail /aws/lambda/smart-city-parking-management-system-lambda-sensor-processing --follow

# Test API Gateway endpoint
curl -X GET https://$(terraform output -raw api_gateway_url)/parking/spaces

# Check RDS status
aws rds describe-db-instances --db-instance-identifier smart-city-parking-management-system-rds-main
```

## Cost Optimization

- Use RDS reserved instances for production
- Configure S3 lifecycle policies
- Set up CloudWatch billing alerts
- Review and optimize Lambda memory allocation

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all data. Ensure you have backups before proceeding.

## Support

For issues and questions:
- Check AWS CloudWatch logs
- Review Terraform state files
- Consult AWS documentation
- Contact system administrators

## License

This infrastructure code is provided for municipal smart city initiatives. Please ensure compliance with local regulations and data protection requirements.