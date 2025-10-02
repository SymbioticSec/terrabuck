# HIPAA-Compliant Patient Portal System

## Overview

This CloudFormation template deploys a comprehensive healthcare patient portal system designed to handle Protected Health Information (PHI) in compliance with HIPAA requirements. The system provides patients with secure access to medical records, appointment scheduling, provider communications, and prescription management.

## Architecture

The system implements a multi-tier architecture with the following components:

### Network Architecture
- **VPC**: Multi-AZ VPC with DNS support
- **Public Subnets**: Host the Application Load Balancer
- **Private Subnets**: Host web application instances
- **Data Subnets**: Isolated subnets for database instances

### Application Components
- **Application Load Balancer**: Distributes traffic with health checks
- **Auto Scaling Group**: Manages web application instances across AZs
- **RDS MySQL Database**: Stores patient records with encryption at rest
- **S3 Buckets**: Document storage and backup storage with versioning
- **CloudWatch Logs**: Centralized audit logging
- **CloudTrail**: API call auditing and compliance logging
- **SQS Queue**: Handles patient communication workflows

## Prerequisites

- AWS CLI configured with appropriate permissions
- CloudFormation deployment permissions
- VPC and EC2 service limits sufficient for deployment

## Deployment Instructions

### Step 1: Clone or Download Template
```bash
# Save the CloudFormation template as main.yaml
# Ensure you have the template file in your working directory
```

### Step 2: Validate Template
```bash
aws cloudformation validate-template --template-body file://main.yaml
```

### Step 3: Deploy Stack
```bash
aws cloudformation create-stack \
  --stack-name hipaa-patient-portal \
  --template-body file://main.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=production \
    ParameterKey=DatabasePassword,ParameterValue=YourSecurePassword123 \
    ParameterKey=InstanceType,ParameterValue=t3.medium \
    ParameterKey=DatabaseInstanceClass,ParameterValue=db.t3.small \