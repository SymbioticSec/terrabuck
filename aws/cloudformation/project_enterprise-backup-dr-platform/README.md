# Enterprise Backup and Disaster Recovery Platform

A comprehensive backup and disaster recovery solution for enterprise clients that provides automated backup scheduling, cross-region replication, and rapid recovery capabilities.

## Architecture Overview

This platform implements a complete backup and disaster recovery solution with the following components:

- **Backup Orchestration Service**: Lambda-based coordination of backup jobs and lifecycle management
- **Backup Storage**: S3-based primary storage with cross-region replication
- **Backup Metadata Database**: RDS MySQL database for backup catalogs and schedules
- **Backup Agents Cluster**: Auto-scaling EC2 instances performing backup operations
- **Recovery Service**: Lambda-based recovery orchestration with progress tracking
- **Monitoring Dashboard**: CloudWatch-based monitoring and alerting

## Prerequisites

- AWS CLI configured with appropriate permissions
- CloudFormation deployment permissions
- VPC and subnet management permissions
- IAM role creation permissions

## Deployment Instructions

### 1. Clone and Prepare

```bash
git clone <repository-url>
cd enterprise-backup-dr-platform
```

### 2. Set Parameters

Create a parameters file `parameters.json`:

```json
[
  {
    "ParameterKey": "Environment",
    "ParameterValue": "production"
  },
  {
    "ParameterKey": "DBPassword",
    "ParameterValue": "YourSecurePassword123!"
  },
  {
    "ParameterKey": "BackupRetentionDays",
    "ParameterValue": "30"
  }
]
```

### 3. Deploy the Stack

```bash
aws cloudformation create-stack \
  --stack-name enterprise-backup-dr-platform \
  --template-body file://main.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### 4. Monitor Deployment

```bash
aws cloudformation describe-stacks \
  --stack-name enterprise-backup-dr-platform \
  --query 'Stacks[0].StackStatus'
```

### 5. Verify Resources

```bash
# Check backup storage bucket
aws s3 ls | grep enterprise-backup

# Check Lambda functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `enterprise-backup`)]'

# Check RDS instance
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `enterprise-backup`)]'
```

## Configuration

### Database Setup

After deployment, initialize the metadata database:

```sql
CREATE DATABASE backup_metadata;
USE backup_metadata;

CREATE TABLE backup_jobs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  job_name VARCHAR(255) NOT NULL,
  source_system VARCHAR(255) NOT NULL,
  backup_type ENUM('full', 'incremental', 'differential'),
  status ENUM('pending', 'running', 'completed', 'failed'),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL
);

CREATE TABLE backup_schedules (
  id INT AUTO_INCREMENT PRIMARY KEY,
  job_name VARCHAR(255) NOT NULL,
  cron_expression VARCHAR(100) NOT NULL,
  retention_days INT DEFAULT 30,
  enabled BOOLEAN DEFAULT TRUE
);
```

### Backup Agent Configuration

The backup agents are automatically configured via UserData script. To customize:

1. Update the LaunchConfiguration UserData
2. Deploy agent-specific configuration via Systems Manager Parameter Store
3. Use the backup orchestration Lambda to manage agent tasks

### Recovery Operations

To perform recovery operations:

```bash
# Invoke recovery service
aws lambda invoke \
  --function-name enterprise-backup-dr-platform-recovery-service \
  --payload '{"backup_id": "backup-123", "target_system": "prod-db-01"}' \
  response.json
```

## Monitoring and Alerting

### CloudWatch Dashboards

The platform creates CloudWatch alarms for:
- Backup job failures
- Storage utilization
- Agent health status
- Recovery operation status

### SNS Notifications

Subscribe to the backup alerts topic:

```bash
aws sns subscribe \
  --topic-arn $(aws cloudformation describe-stacks --stack-name enterprise-backup-dr-platform --query 'Stacks[0].Outputs[?OutputKey==`BackupAlertsTopicArn`].OutputValue' --output text) \
  --protocol email \
  --notification-endpoint your-email@company.com
```

## Security Considerations

### IAM Permissions

The platform uses least-privilege IAM roles:
- Backup orchestration role: Limited to backup coordination
- Backup agents role: Access to source systems and storage
- Recovery service role: Recovery-specific permissions

### Encryption

- S3 buckets use server-side encryption
- RDS database uses encryption at rest
- EFS file system should be encrypted (update template)

### Network Security

- Backup agents run in private subnets
- Database is isolated in data subnet
- Security groups restrict access to necessary ports only

## Troubleshooting

### Common Issues

1. **Backup Jobs Failing**
   - Check CloudWatch logs for Lambda functions
   - Verify IAM permissions
   - Check network connectivity from agents

2. **Database Connection Issues**
   - Verify security group rules
   - Check subnet routing
   - Validate database credentials

3. **Storage Access Problems**
   - Check S3 bucket policies
   - Verify IAM permissions
   - Check cross-region replication status

### Log Locations

- Backup orchestration logs: `/aws/lambda/enterprise-backup-dr-platform-backup-jobs`
- Recovery service logs: `/aws/lambda/enterprise-backup-dr-platform-recovery`
- Agent logs: EC2 instances in `/var/log/backup-agent/`

## Maintenance

### Regular Tasks

1. **Monitor Storage Costs**
   - Review S3 storage class transitions
   - Clean up old backup data per retention policies

2. **Update Backup Agents**
   - Update Launch Configuration with new AMI
   - Perform rolling updates of Auto Scaling Group

3. **Database Maintenance**
   - Monitor RDS performance metrics
   - Apply security patches during maintenance windows

### Scaling

To scale the platform:

1. **Increase Agent Capacity**
   ```bash
   aws autoscaling update-auto-scaling-group \
     --auto-scaling-group-name enterprise-backup-dr-platform-backup-agents-asg \
     --desired-capacity 5
   ```

2. **Upgrade Database**
   ```bash
   aws rds modify-db-instance \
     --db-instance-identifier enterprise-backup-dr-platform-metadata-db \
     --db-instance-class db.t3.large \
     --apply-immediately
   ```

## Cost Optimization

- Use S3 Intelligent Tiering for backup storage
- Implement lifecycle policies for old backups
- Use Spot instances for non-critical backup agents
- Monitor and optimize Lambda function execution time

## Support

For issues and support:
- Check CloudWatch logs and metrics
- Review AWS CloudFormation events
- Contact the backup platform team

## License

This project is licensed under the MIT License - see the LICENSE file for details.