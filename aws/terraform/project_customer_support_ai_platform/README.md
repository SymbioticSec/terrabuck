# AI-Powered Customer Support Platform

This Terraform configuration deploys a comprehensive customer support platform that integrates AI chatbots, ticket management, and knowledge base search on AWS.

## Architecture Overview

The platform consists of:
- **Web Application Tier**: EC2 instances hosting the customer support portal and admin dashboard
- **AI Processing Service**: Lambda functions for ticket classification and sentiment analysis
- **Ticket Database**: PostgreSQL RDS instance for storing tickets and user data
- **Knowledge Base Storage**: S3 bucket for support articles and chat logs
- **API Gateway**: RESTful endpoints for mobile apps and integrations
- **Load Balancer**: Application Load Balancer for traffic distribution

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Sufficient AWS permissions for creating VPC, EC2, RDS, S3, Lambda, and API Gateway resources

## Deployment Instructions

1. **Clone and Navigate**
   ```bash
   git clone <repository-url>
   cd ai-customer-support-platform
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Create Lambda Deployment Packages**
   ```bash
   # Create placeholder Lambda packages
   echo 'def handler(event, context): return {"statusCode": 200}' > lambda_function.py
   zip ai_classifier.zip lambda_function.py
   zip sentiment_analysis.zip lambda_function.py
   ```

4. **Create User Data Script**
   ```bash
   cat > user_data.sh << 'EOF'
   #!/bin/bash
   apt-get update
   apt-get install -y nginx
   systemctl start nginx
   systemctl enable nginx
   echo "<h1>Customer Support Platform - Server $(hostname)</h1>" > /var/www/html/index.html
   echo "<p>Database: ${db_host}</p>" >> /var/www/html/index.html
   EOF
   ```

5. **Review and Customize Variables**
   ```bash
   # Edit terraform.tfvars if needed
   cat > terraform.tfvars << 'EOF'
   aws_region = "us-west-2"
   environment = "production"
   db_password = "your-secure-password-here"
   EOF
   ```

6. **Plan Deployment**
   ```bash
   terraform plan
   ```

7. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

8. **Access the Platform**
   - Web Portal: Use the `load_balancer_dns` output
   - API Endpoints: Use the `api_gateway_url` output
   - Database: Connect using the `database_endpoint` output

## Configuration Details

### Network Architecture
- Multi-AZ VPC with public and private subnets
- Internet Gateway for public access
- Security groups with least-privilege access
- Database isolated in private subnets

### Security Features
- RDS encryption at rest
- S3 server-side encryption
- IAM roles with specific permissions
- Security groups restricting access

### Scaling Capabilities
- Auto Scaling Groups for web tier (can be added)
- Lambda functions scale automatically
- RDS supports read replicas (can be configured)
- S3 provides unlimited storage

## Monitoring and Maintenance

### Health Checks
- ALB performs health checks on web instances
- RDS automated backups enabled
- Lambda functions have CloudWatch logging

### Backup Strategy
- RDS automated backups (7-day retention)
- S3 versioning can be enabled
- Database maintenance window configured

## Troubleshooting

### Common Issues
1. **Lambda deployment fails**: Ensure zip files exist in the current directory
2. **Database connection issues**: Check security group rules and VPC configuration
3. **Load balancer health checks fail**: Verify nginx is running on web instances

### Useful Commands
```bash
# Check resource status
terraform show

# View outputs
terraform output

# Destroy infrastructure
terraform destroy
```

## Cost Optimization

- Use t3.micro instances for development
- Enable S3 lifecycle policies for old data
- Consider Reserved Instances for production
- Monitor CloudWatch costs regularly

## Security Considerations

- Change default database password
- Enable MFA for AWS accounts
- Regularly update AMIs and security patches
- Review IAM permissions periodically
- Enable CloudTrail for audit logging

## Support

For issues with this deployment:
1. Check Terraform logs for error details
2. Verify AWS permissions and quotas
3. Review security group and network ACL rules
4. Consult AWS documentation for service-specific issues