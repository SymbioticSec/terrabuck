# Enterprise CI/CD Platform with Artifact Management

This CloudFormation template deploys a comprehensive DevOps platform for a mid-size software company, providing automated build pipelines, artifact storage, deployment automation, and code quality gates.

## Architecture Overview

The platform supports multiple development teams with isolated environments, automated testing, and secure artifact distribution across development, staging, and production environments.

### Components Deployed

1. **Network Infrastructure**
   - Multi-AZ VPC with public and private subnets
   - Internet Gateway and routing tables
   - Security groups for build and application tiers

2. **Source Control Integration** (CodeCommit)
   - Git-based source code repository
   - Integration hooks for pipeline triggers

3. **Build Orchestration** (CodeBuild)
   - Automated build processes
   - Unit test execution
   - Code quality analysis

4. **Artifact Storage** (S3)
   - Build artifacts and deployment packages
   - Versioned releases with lifecycle policies
   - KMS encryption for sensitive data

5. **Deployment Automation** (CodeDeploy)
   - Automated deployments across environments
   - Blue-green and rolling deployment strategies
   - Rollback capabilities

6. **Pipeline Orchestration** (CodePipeline)
   - End-to-end CI/CD workflow coordination
   - Approval gates for production deployments
   - Integration with all platform components

7. **Target Infrastructure** (EC2 Auto Scaling)
   - Scalable compute infrastructure
   - Multi-environment support
   - Automated scaling based on demand

8. **Notification System** (SNS)
   - Build status notifications
   - Deployment alerts and failure notifications
   - Integration with email and Slack

## Prerequisites

- AWS CLI configured with appropriate permissions
- EC2 Key Pair for SSH access to instances
- Sufficient IAM permissions to create all resources

## Deployment Instructions

### Step 1: Prepare Parameters

Create a parameters file `parameters.json`:

```json
[
  {
    "ParameterKey": "ProjectName",
    "ParameterValue": "enterprise-ci-cd-platform"
  },
  {
    "ParameterKey": "Environment",
    "ParameterValue": "production"
  },
  {
    "ParameterKey": "KeyPairName",
    "ParameterValue": "your-key-pair-name"
  },
  {
    "ParameterKey": "VpcCidr",
    "ParameterValue": "10.0.0.0/16"
  },
  {
    "ParameterKey": "PublicSubnet1Cidr",
    "ParameterValue": "10.0.1.0/24"
  },
  {
    "ParameterKey": "PrivateSubnet1Cidr",
    "ParameterValue": "10.0.2.0/24"
  },
  {
    "ParameterKey": "InstanceType",
    "ParameterValue": "t3.medium"
  }
]
```

### Step 2: Deploy the Stack

```bash
aws cloudformation create-stack \
  --stack-name enterprise-ci-cd-platform \
  --template-body file://main.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Step 3: Monitor Deployment

```bash
aws cloudformation describe-stacks \
  --stack-name enterprise-ci-cd-platform \
  --query 'Stacks[0].StackStatus'
```

### Step 4: Retrieve Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name enterprise-ci-cd-platform \
  --query 'Stacks[0].Outputs'
```

## Post-Deployment Configuration

### 1. Configure Source Repository

```bash
# Clone the repository
REPO_URL=$(aws cloudformation describe-stacks \
  --stack-name enterprise-ci-cd-platform \
  --query 'Stacks[0].Outputs[?OutputKey==`SourceRepositoryCloneUrl`].OutputValue' \
  --output text)

git clone $REPO_URL
cd enterprise-ci-cd-platform-source

# Add your application code and buildspec.yml
```

### 2. Create BuildSpec File

Create `buildspec.yml` in your repository:

```yaml
version: 0.2
phases:
  install:
    runtime-versions:
      nodejs: 14
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - npm install
  build:
    commands:
      - echo Build started on `date`
      - npm run build
      - npm run test
  post_build:
    commands:
      - echo Build completed on `date`
artifacts:
  files:
    - '**/*'
  name: BuildArtifact
```

### 3. Configure SNS Notifications

```bash
# Subscribe to notifications
TOPIC_ARN=$(aws cloudformation describe-stacks \
  --stack-name enterprise-ci-cd-platform \
  --query 'Stacks[0].Outputs[?OutputKey==`NotificationTopicArn`].OutputValue' \
  --output text)

aws sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol email \
  --notification-endpoint your-email@company.com
```

## Usage

### Triggering Builds

1. **Automatic Triggers**: Push code to the main branch of the CodeCommit repository
2. **Manual Triggers**: Start pipeline execution from AWS Console or CLI

```bash
PIPELINE_NAME=$(aws cloudformation describe-stacks \
  --stack-name enterprise-ci-cd-platform \
  --query 'Stacks[0].Outputs[?OutputKey==`PipelineName`].OutputValue' \
  --output text)

aws codepipeline start-pipeline-execution \
  --name $PIPELINE_NAME
```

### Monitoring

- **CodePipeline Console**: Monitor pipeline execution status
- **CodeBuild Console**: View build logs and metrics
- **CloudWatch**: Monitor infrastructure metrics and logs
- **SNS Notifications**: Receive alerts via email

### Scaling

The Auto Scaling Group automatically adjusts capacity based on demand:
- **Minimum**: 1 instance
- **Maximum**: 3 instances  
- **Desired**: 2 instances

## Security Considerations

This template includes several security features:
- VPC isolation with public/private subnet separation
- IAM roles with least-privilege access
- KMS encryption for artifacts
- Security groups restricting network access
- CloudTrail for audit logging

## Troubleshooting

### Common Issues

1. **Stack Creation Fails**
   - Check IAM permissions
   - Verify EC2 Key Pair exists
   - Ensure unique S3 bucket naming

2. **Pipeline Fails**
   - Check CodeBuild logs
   - Verify buildspec.yml syntax
   - Ensure proper IAM permissions

3. **Deployment Fails**
   - Check CodeDeploy agent installation
   - Verify application revision format
   - Review deployment configuration

### Cleanup

To delete the entire stack:

```bash
aws cloudformation delete-stack \
  --stack-name enterprise-ci-cd-platform
```

**Note**: Ensure S3 bucket is empty before deletion.

## Cost Optimization

- Use appropriate instance types for your workload
- Configure lifecycle policies for artifact retention
- Monitor CloudWatch metrics to optimize scaling policies
- Consider using Spot instances for non-production environments

## Support

For issues and questions:
- Review CloudFormation events in AWS Console
- Check service-specific logs (CodeBuild, CodeDeploy)
- Monitor CloudWatch metrics and alarms
- Review IAM permissions and policies