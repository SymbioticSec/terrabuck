# AWS CloudFormation Projects

This directory contains multiple AWS CloudFormation reference projects. Each subproject demonstrates a realistic enterprise use case with an IaC template (`main.yaml`), inputs (`variables.yaml`), outputs (`outputs.yaml`), and documentation/metadata under `metadata/`.

- Each project folder includes its own detailed `README.md`.
- Metadata: `metadata/project_metadata.json` provides use-case, components, and injected vulnerabilities; `component_analysis.json` and label files add more context.

## Subprojects

The following subprojects are included (follow the links to each project's README for details):

- `project_corporate-knowledge-hub-v1/` – Corporate Knowledge Management Hub
- `project_digital-asset-custody-platform/` – Digital Asset Custody Platform
- `project_enterprise-backup-dr-platform/` – Enterprise Backup & DR Platform
- `project_enterprise-ci-cd-platform/` – Enterprise CI/CD Platform with Artifact Mgmt
- `project_enterprise-document-mgmt-platform/` – Enterprise Document Management Platform
- `project_enterprise-identity-sso-platform/` – Enterprise Identity & SSO Platform
- `project_enterprise-monitoring-alerting-platform/` – Enterprise Monitoring & Alerting
- `project_enterprise_api_gateway_platform/` – Enterprise API Gateway & Mgmt
- `project_event-streaming-platform/` – Real-Time Event Streaming Analytics
- `project_fintech-trading-platform-001/` – Real-Time Trading Platform Backend
- `project_fleet-management-gps-platform/` – Fleet Management GPS Tracking
- `project_healthcare-patient-portal-hipaa/` – HIPAA-Compliant Patient Portal
- `project_iot-sensor-analytics-platform/` – Smart Manufacturing IoT Analytics
- `project_social-media-analytics-platform/` – Social Media Analytics Platform
- `project_video-streaming-platform/` – Enterprise Video Streaming Platform

## Typical Components

Projects typically contain combinations of these components (see `project_metadata.json: project_info.components` for the exact list per project):

- API and ingress: API Gateway, Application Load Balancer, CloudFront
- Compute: EC2, ECS/Fargate, Lambda
- Data stores: RDS (PostgreSQL/MySQL), DynamoDB, Timestream, ElastiCache (Redis), S3
- Streaming/eventing: Kinesis, SQS, SNS
- Observability & security: CloudWatch, CloudTrail, IAM, VPC constructs

## Injected Vulnerability Themes

Each project intentionally includes several misconfigurations for training and scanning validation. Common examples (severity varies by project):

- S3 public access blocks missing, logging disabled, MFA delete not enforced
- RDS publicly accessible or without customer-managed KMS, missing Performance Insights KMS
- EC2/ASG IMDSv2 not enforced, unencrypted EBS, permissive SG/ACL rules
- IAM weak password policies, missing MFA enforcement, overbroad S3 permissions
- CloudFront not enforcing HTTPS or using weak TLS policy
- Lambda/API Gateway missing X-Ray tracing; Lambda permissions without SourceArn
- ElastiCache lacking at-rest or in-transit encryption; missing backup retention
- CloudTrail not multi-region, missing CloudWatch integration or object-level S3 data events

Refer to each subproject’s `metadata/project_metadata.json` → `vulnerabilities[]` for the precise rules injected (rule_id, title, description, severity, affected_component).
