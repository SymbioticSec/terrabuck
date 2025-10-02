# Enterprise Identity and SSO Platform

Enterprise identity management with SSO, MFA, centralized directory, and audit logging.

## Overview
- Cloud: AWS
- IaC: CloudFormation
- Architecture: microservices

## Components
- identity_service_cluster (aws_ecs_fargate): AuthN/Z, SAML/OAuth providers.
- user_directory_database (aws_rds_postgresql): Users, roles, groups.
- session_cache (aws_elasticache_redis): Sessions and SSO tokens.
- audit_storage (aws_s3_bucket): Authentication event logs.
- application_load_balancer (aws_application_load_balancer): Fronts identity services.
- mfa_notification_service (aws_lambda): MFA workflows and notifications.

## Notable Vulnerabilities (intentional)
- ElastiCache At-Rest Encryption Disabled (medium) – session_cache
- RDS Public Access Enabled (medium) – user_directory_database
- ECS Cluster Missing Container Insights (medium) – identity_service_cluster
- ALB Not Dropping Invalid Headers (medium) – application_load_balancer
- CloudWatch LogGroup Missing Customer Key (medium) – audit_storage
- IAM Password Policy Missing Symbols (medium) – identity_service_cluster
- SG Missing Description (medium) – identity_service_cluster

## Quick Scan
- Checkov: `checkov -d .`
- cfn-nag: `cfn_nag_scan --input-path .`

## Responsible Use
Intentionally insecure for learning. Do not deploy to production.
