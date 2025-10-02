# Enterprise Document Management Platform

A secure document management system designed for mid-size law firms handling sensitive legal documents. This CloudFormation template deploys a complete infrastructure including web application tier, document storage, metadata database, search engine, and document processing capabilities.

## Architecture Overview

The platform consists of the following components:

- **Web Application Tier**: Auto-scaled EC2 instances behind an Application Load Balancer
- **Document Storage**: S3 bucket with versioning and lifecycle policies
- **Metadata Database**: PostgreSQL RDS instance for document metadata and audit trails
- **Search Engine**: Elasticsearch domain for full-text search capabilities
- **Document Processor**: Lambda function for document processing tasks
- **Network Infrastructure**: VPC with public/private subnets across two AZs

## Prerequisites

- AWS CLI configured with appropriate permissions
- CloudFormation deployment permissions
- VPC and EC2 service limits sufficient for the deployment

## Deployment Instructions

### 1. Clone or Download Template

Save the CloudFormation template as `main.yaml`.

### 2. Deploy the Stack

```bash
aws cloudformation create-stack \
  --stack-name enterprise-document-mgmt \
  --template-body file://main.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=production \
    ParameterKey=DatabasePassword,ParameterValue=YourSecurePassword123! \
    ParameterKey=DatabaseInstanceClass,ParameterValue=db.t3.medium \
  --capabilities CAPABILITY_NAMED_IAM
```

### 3. Monitor Deployment

```bash
aws cloudformation describe-stacks \
  --stack-name enterprise-document-mgmt \
  --query 'Stacks[0].StackStatus'
```

### 4. Retrieve Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name enterprise-document-mgmt \
  --query 'Stacks[0].Outputs'
```

## Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| Environment | production | Environment name (development/staging/production) |
| ProjectName | enterprise-document-mgmt-platform | Project name for resource naming |
| VpcCidr | 10.0.0.0/16 | CIDR block for VPC |
| DatabaseUsername | docmgmt_admin | Database master username |
| DatabasePassword | (required) | Database master password (minimum 8 characters) |
| DatabaseInstanceClass | db.t3.medium | RDS instance class |

## Post-Deployment Configuration

### 1. Database Setup

Connect to the RDS instance and create the application database schema:

```sql
CREATE DATABASE document_management;
CREATE USER app_user WITH PASSWORD 'app_password';
GRANT ALL PRIVILEGES ON DATABASE document_management TO app_user;
```

### 2. Elasticsearch Index Configuration

Configure Elasticsearch indices for document search:

```bash
curl -X PUT "https://your-es-domain/documents" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "title": { "type": "text" },
      "content": { "type": "text" },
      "client_id": { "type": "keyword" },
      "case_id": { "type": "keyword" },
      "created_date": { "type": "date" }
    }
  }
}'
```

### 3. Application Deployment

Deploy your web application to the EC2 instances using your preferred deployment method (CodeDeploy, Ansible, etc.).

## Security Considerations

This template implements several security measures:

- VPC with private subnets for database and application tiers
- Security groups with least-privilege access
- IAM roles with minimal required permissions
- S3 bucket versioning and lifecycle policies
- RDS Multi-AZ deployment for high availability

## Monitoring and Logging

The infrastructure includes:

- CloudWatch monitoring for all resources
- Auto Scaling for web application tier
- RDS automated backups
- VPC Flow Logs (can be enabled post-deployment)

## Estimated Costs

Monthly cost estimates (us-east-1 region):

- EC2 instances (2x t3.medium): ~$60
- RDS PostgreSQL (db.t3.medium): ~$45
- Elasticsearch (2x t3.small): ~$50
- S3 storage: Variable based on usage
- Data transfer: Variable based on usage

Total estimated monthly cost: ~$155 + storage and transfer costs

## Cleanup

To delete the entire infrastructure:

```bash
aws cloudformation delete-stack --stack-name enterprise-document-mgmt
```

**Note**: Ensure S3 buckets are empty before deletion, as CloudFormation cannot delete non-empty buckets.

## Support

For issues or questions regarding this deployment:

1. Check CloudFormation stack events for deployment errors
2. Review CloudWatch logs for application issues
3. Verify security group and IAM permissions
4. Ensure all prerequisites are met

## License

This template is provided as-is for educational and deployment purposes. Ensure compliance with your organization's security policies before production use.