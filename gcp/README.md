# Google Cloud (GCP) Terraform Projects

This directory contains multiple Google Cloud reference projects implemented with Terraform. Each subproject demonstrates a realistic enterprise use case with IaC files (`main.tf`, `variables.tf`, `outputs.tf`) and project metadata under `metadata/`.

- Each project folder includes its own detailed `README.md`.
- Metadata: `metadata/project_metadata.json` describes the use case, components, and injected misconfigurations; `component_analysis.json` and label files provide additional context.

## Subprojects

Follow each link to the subproject’s README for details:

- `project_gcp-digital-asset-trading/` – Digital Asset Trading Platform
- `project_gcp-digital-library-platform/` – Digital Library Platform
- `project_gcp-fintech-trading-platform/` – Fintech Trading Platform
- `project_gcp-fleet-management-platform/` – Fleet Management Platform
- `project_gcp-insurance-claims-processing/` – Insurance Claims Processing
- `project_gcp-iot-manufacturing-mes/` – IoT Manufacturing MES
- `project_gcp-media-streaming-platform/` – Media Streaming Platform
- `project_gcp-restaurant-pos-system/` – Restaurant POS System
- `project_gcp-telehealth-platform/` – Telehealth Platform
- `project_gcp_carbon_tracking_platform/` – Carbon Tracking Platform
- `project_gcp_disaster_recovery_platform/` – Disaster Recovery Platform
- `project_gcp_drone_delivery_platform/` – Drone Delivery Platform
- `project_gcp_ecommerce_analytics_platform/` – eCommerce Analytics Platform
- `project_healthcare-patient-portal-hipaa/` – HIPAA-Compliant Patient Portal
- `project_smart_city_traffic_management/` – Smart City Traffic Management

## Typical Components

Projects commonly use:

- API and ingress: Cloud Load Balancing (HTTP(S)/TCP), Cloud CDN
- Compute: Compute Engine (GCE), GKE (Kubernetes), Cloud Run, Cloud Functions
- Data stores: Cloud SQL (PostgreSQL/MySQL), Firestore/Datastore, Bigtable, Memorystore (Redis), Cloud Storage (GCS)
- Streaming/eventing: Pub/Sub, Dataflow
- Observability & security: Cloud Logging/Monitoring, Cloud Audit Logs, IAM, VPC networks/Subnets/Firewall rules, Secret Manager, KMS

See each subproject’s `metadata/project_metadata.json -> project_info.components` for exact components.

## Injected Vulnerability Themes

Each project intentionally includes several misconfigurations for training and scanning validation. Common examples:

- Cloud Storage: public access allowed, uniform bucket-level access disabled, logging not enabled
- Cloud SQL: public IP enabled, CMEK not used, insufficient log/audit settings
- Compute/GKE/Run: overly permissive firewall rules (0.0.0.0/0), plaintext secrets in metadata/env, weak service account scopes
- Identity: weak password policies or MFA gaps (where applicable), overbroad IAM bindings (roles/*), service accounts with owner/editor
- Networking: default networks used, public IPs on private tiers, unrestricted egress
- Observability: sinks/metrics/alerts not configured, Audit Logs not routed/retained, missing org policies

For exact injected rules, review `metadata/project_metadata.json -> vulnerabilities[]` in each subproject.
