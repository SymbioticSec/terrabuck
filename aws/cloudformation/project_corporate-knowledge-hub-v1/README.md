# Corporate Knowledge Management Hub

A secure enterprise knowledge management platform enabling employees to upload, search, and collaborate on documents with role-based access and audit trails.

## Overview
- Cloud: AWS
- IaC: CloudFormation
- Architecture: microservices

## Components
- web_application_tier (aws_ec2_instance): Hosts the web UI and Node.js API.
- document_storage (aws_s3_bucket): Stores uploaded documents with versioning.
- search_engine (aws_elasticsearch): Full-text search across documents.
- user_database (aws_rds_mysql): User profiles, permissions, and audit logs.
- document_processor (aws_lambda): Extracts text and triggers indexing.
- load_balancer (aws_application_load_balancer): SSL termination and traffic distribution.

## Notable Vulnerabilities (intentional)
- S3 Bucket Missing Customer-Managed Encryption (medium) – document_storage
- S3 Bucket Missing Public Access Block (medium) – document_storage
- RDS Database Missing Customer-Managed Encryption (medium) – user_database
- EC2 SG Allows Unrestricted Outbound (medium) – web_application_tier
- Lambda Missing X-Ray Tracing (medium) – document_processor
- ALB Not Dropping Invalid Headers (medium) – load_balancer
- IAM Groups Missing MFA Enforcement (medium) – web_application_tier

## Quick Scan
- Checkov: `checkov -d .`
- cfn-nag: `cfn_nag_scan --input-path .`

## Responsible Use
These templates are intentionally insecure. Do not deploy to production. Use isolated accounts and clean up after testing.
