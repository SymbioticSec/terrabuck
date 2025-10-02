# AWS Terraform Projects

This directory contains multiple AWS Terraform reference projects. Each subproject demonstrates a realistic enterprise use case with IaC files (`main.tf`, `variables.tf`, `outputs.tf`) and project metadata under `metadata/`.

- Each project folder includes its own detailed `README.md`.
- Metadata: `metadata/project_metadata.json` describes the use case, components, and injected misconfigurations; `component_analysis.json` and label files provide additional context.

## Subprojects

Follow each link to the subproject’s README for details:

- `project_corporate-backup-disaster-recovery/` – Enterprise Backup & DR Platform
- `project_customer_support_ai_platform/` – Customer Support AI Platform
- `project_digital-asset-trading-platform/` – Digital Asset Trading Platform
- `project_employee-onboarding-automation/` – Employee Onboarding Automation
- `project_enterprise_api_gateway_platform/` – Enterprise API Gateway & Mgmt
- `project_enterprise_knowledge_base/` – Enterprise Knowledge Base
- `project_enterprise_log_analytics_platform/` – Enterprise Log Analytics
- `project_fintech_trading_platform/` – Fintech Trading Platform
- `project_fleet-management-gps-tracker/` – Fleet Management GPS Tracker
- `project_global-content-delivery-platform/` – Global Content Delivery Platform
- `project_healthcare-patient-portal-hipaa/` – HIPAA-Compliant Patient Portal
- `project_iot-sensor-analytics-platform/` – Smart Manufacturing IoT Analytics
- `project_restaurant_pos_inventory_system/` – Restaurant POS & Inventory
- `project_smart_parking_mgmt_system/` – Smart Parking Management System
- `project_video-streaming-platform/` – Enterprise Video Streaming Platform

## Typical Components

Projects commonly use:

- API and ingress: API Gateway, Application/Network Load Balancer, CloudFront
- Compute: EC2, ECS/Fargate, Lambda
- Data stores: RDS (PostgreSQL/MySQL), DynamoDB, ElastiCache (Redis), S3
- Streaming/eventing: Kinesis, SQS, SNS
- Observability & security: CloudWatch, CloudTrail, IAM, VPC constructs

See each subproject’s `metadata/project_metadata.json -> project_info.components` for exact components.

## Injected Vulnerability Themes

Each project intentionally includes several misconfigurations for training and scanning validation. Common examples:

- S3: public access blocks missing, access logging disabled, MFA delete not enforced
- RDS: public accessibility enabled, no customer-managed KMS, Performance Insights KMS missing
- EC2/ASG: IMDSv2 not required, unencrypted EBS, permissive SG/ACL rules, secrets in user_data
- IAM: weak password policies (length/uppercase/symbols/reuse), missing MFA enforcement, overbroad S3 permissions
- CloudFront/API Gateway/Lambda: HTTPS not enforced, weak TLS policy, X-Ray tracing disabled, missing source ARN restrictions
- ElastiCache: missing at-rest or in-transit encryption, no backup retention
- CloudTrail: not multi-region, no CloudWatch integration, missing S3 data events

For exact injected rules, review `metadata/project_metadata.json -> vulnerabilities[]` in each subproject.
