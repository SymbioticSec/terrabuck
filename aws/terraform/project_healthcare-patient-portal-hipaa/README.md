# HIPAA-Compliant Patient Portal Infrastructure

This Terraform configuration deploys a multi-tier healthcare patient portal infrastructure on AWS, designed to handle sensitive patient health information (PHI) while maintaining HIPAA compliance requirements.

## Architecture Overview

The infrastructure implements a secure 3-tier architecture:

- **Presentation Tier**: Application Load Balancer in public subnets
- **Application Tier**: EC2 web servers in private subnets
- **Data Tier**: RDS MySQL database in isolated private subnets

### Components Deployed

1. **VPC and Networking**: Multi-AZ VPC with public, private app, and private data subnets
2. **Application Load Balancer**: Distributes traffic across web servers with SSL termination
3. **Web Application Tier**: Auto-scaled EC2 instances hosting the patient portal
4. **Database Tier**: RDS MySQL instance storing patient data and authentication
5. **File Storage**: S3 bucket for medical documents and patient uploads
6. **Backup Storage**: S3 bucket for encrypted database and file backups
7. **Audit Logging**: CloudWatch logs and CloudTrail for HIPAA compliance

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Appropriate AWS IAM permissions for resource creation

## Deployment Instructions

1. **Clone and Navigate**
   ```bash
   git clone <repository-url>
   cd hipaa-patient-portal-infrastructure
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review and Customize Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

4. **Plan Deployment**
   ```bash
   terraform plan
   ```

5. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

6. **Access the Application**
   - The load balancer DNS name will be output after deployment
   - Access via: `http://<load-balancer-dns>`

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-east-1` |
| `environment` | Environment name | `production` |
| `instance_type` | EC2 instance type for web servers | `t3.medium` |
| `db_instance_class` | RDS instance class | `db.t3.micro` |
| `db_password` | Database password (change default!) | `ChangeMe123!` |

## Security Features

- **Network Isolation**: Multi-tier subnet architecture with security groups
- **Encryption**: EBS volumes encrypted, S3 server-side encryption
- **Access Control**: Least-privilege security group rules
- **Audit Logging**: CloudTrail and CloudWatch for compliance monitoring
- **High Availability**: Multi-AZ deployment with load balancing

## HIPAA Compliance Considerations

This infrastructure implements several HIPAA safeguards:

- **Administrative Safeguards**: CloudTrail audit logging, access controls
- **Physical Safeguards**: AWS data center security, encrypted storage
- **Technical Safeguards**: Encryption in transit/rest, access controls, audit logs

## Monitoring and Maintenance

- **CloudWatch Logs**: Application and system logs in `/aws/hipaa-patient-portal/audit`
- **CloudTrail**: API call logging for audit trail
- **Backup Strategy**: Automated RDS backups, S3 versioning enabled
- **Updates**: Regular security patching required for EC2 instances

## Cost Optimization

- **Instance Sizing**: Start with t3.medium, scale based on usage
- **Storage**: Use GP3 volumes for better price/performance
- **Backup Retention**: Configure appropriate retention periods
- **Monitoring**: Set up billing alerts and cost monitoring

## Disaster Recovery

- **Multi-AZ**: Database and application deployed across availability zones
- **Backups**: Automated daily backups with point-in-time recovery
- **Cross-Region**: Consider cross-region backup replication for DR

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources and data. Ensure backups are secured before destruction.

## Support and Troubleshooting

### Common Issues

1. **Database Connection Failures**: Check security group rules and subnet routing
2. **Load Balancer Health Checks**: Verify web server configuration and security groups
3. **S3 Access Issues**: Review bucket policies and IAM permissions

### Logs and Debugging

- EC2 instance logs: `/var/log/` on instances
- Application logs: CloudWatch log group `/aws/hipaa-patient-portal/audit`
- Load balancer logs: Enable ALB access logging if needed

## Compliance and Security Notes

- **Regular Security Reviews**: Conduct periodic security assessments
- **Access Auditing**: Review CloudTrail logs regularly
- **Patch Management**: Keep EC2 instances updated with security patches
- **Encryption Key Management**: Consider using AWS KMS for enhanced key control

For production deployments, additional security hardening and compliance measures may be required based on specific organizational requirements and regulatory guidance.