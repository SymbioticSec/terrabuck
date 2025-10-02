# Enterprise Knowledge Management System

This Terraform configuration deploys a comprehensive knowledge management platform for large enterprises to centralize documentation, enable intelligent search across multiple content types, and provide secure access controls.

## Architecture Overview

The system implements a microservices architecture with the following components:

- **Document Storage**: S3 bucket for storing all document types with versioning
- **Search Cluster**: Elasticsearch domain for full-text search and indexing
- **Document Processor**: Lambda function for processing and indexing documents
- **Web Application**: ECS Fargate service providing the main web interface
- **User Database**: RDS PostgreSQL for user profiles and document metadata
- **Load Balancer**: Application Load Balancer for traffic distribution

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions

## Deployment Instructions

1. **Clone and Navigate**
   ```bash
   git clone <repository>
   cd enterprise-knowledge-management-system
   ```

2. **Create Lambda Deployment Package**
   ```bash
   # Create a dummy Lambda function zip file
   echo 'def handler(event, context): return {"statusCode": 200}' > index.py
   zip document_processor.zip index.py
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
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

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-west-2` |
| `project_name` | Project name for resource naming | `enterprise-knowledge-management-system` |
| `environment` | Environment name | `production` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `db_instance_class` | RDS instance class | `db.t3.micro` |
| `db_username` | Database username | `knowledge_admin` |
| `db_password` | Database password | `ChangeMe123!` |
| `elasticsearch_instance_type` | Elasticsearch instance type | `t3.small.elasticsearch` |

## Network Architecture

- **Public Subnets**: Load balancer and NAT gateway
- **Private Subnets**: ECS tasks and Lambda functions
- **Data Subnets**: RDS database and Elasticsearch cluster

## Security Features

- VPC with multiple availability zones
- Security groups with least-privilege access
- Encryption at rest for Elasticsearch
- CloudTrail for audit logging
- Secrets Manager for sensitive configuration

## Post-Deployment Steps

1. **Configure Application**
   - Update ECS task definition with actual application image
   - Configure Elasticsearch index mappings
   - Set up database schema

2. **Security Hardening**
   - Review and tighten security group rules
   - Configure WAF rules for the load balancer
   - Set up CloudWatch monitoring and alerting

3. **Application Setup**
   - Deploy application code to ECS
   - Configure Lambda function for document processing
   - Set up initial user accounts and permissions

## Monitoring and Maintenance

- CloudWatch logs are configured for ECS tasks
- Elasticsearch cluster monitoring is enabled
- Database automated backups are configured
- CloudTrail provides audit logging

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Note**: Ensure all data is backed up before destroying resources.

## Support

For issues and questions, please refer to the project documentation or contact the infrastructure team.