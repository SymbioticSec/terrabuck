# Azure Terraform Projects

This directory contains multiple Azure reference projects implemented with Terraform. Each subproject demonstrates a realistic enterprise use case with IaC files (`main.tf`, `variables.tf`, `outputs.tf`) and project metadata under `metadata/`.

- Each project folder includes its own detailed `README.md`.
- Metadata: `metadata/project_metadata.json` describes the use case, components, and injected misconfigurations; `component_analysis.json` and label files provide additional context.

## Subprojects

Follow each link to the subproject’s README for details:

- `project_azure-energy-scada-monitoring/` – Energy SCADA Monitoring Platform
- `project_azure-legal-docmgmt-platform/` – Legal Document Management Platform
- `project_azure-media-streaming-platform/` – Media Streaming Platform
- `project_azure-retail-ecommerce-platform/` – Retail eCommerce Platform
- `project_azure-telehealth-platform/` – Telehealth Platform
- `project_azure_disaster_recovery_platform/` – Disaster Recovery Platform
- `project_azure_fleet_management_platform/` – Fleet Management Platform
- `project_fintech-trading-platform/` – Fintech Trading Platform
- `project_healthcare-patient-portal-hipaa/` – HIPAA-Compliant Patient Portal
- `project_iot-manufacturing-monitoring/` – IoT Manufacturing Monitoring

## Typical Components

Projects commonly use:

- API and ingress: Azure Front Door, Application Gateway, Azure CDN
- Compute: Azure VM Scale Sets, App Service, Azure Functions, AKS
- Data stores: Azure SQL/Managed Instance, Cosmos DB, Azure Storage (Blob), Redis Cache
- Streaming/eventing: Event Hubs, Service Bus, Event Grid
- Observability & security: Azure Monitor/Log Analytics, Azure Policy, Defender for Cloud, Key Vault, VNets/Subnets/NSGs

See each subproject’s `metadata/project_metadata.json -> project_info.components` for exact components.

## Injected Vulnerability Themes

Each project intentionally includes several misconfigurations for training and scanning validation. Common examples:

- Storage: public access not blocked, HTTPS-only disabled, logging/diagnostics missing, no private endpoints
- Databases: public network access enabled, CMK not configured, auditing/diagnostic settings missing
- Compute: secrets in app settings/user-data, overbroad role assignments, missing managed identity, HTTP instead of HTTPS
- Networking: NSGs with 0.0.0.0/0, public IPs on private tiers, missing DDoS/network policies
- Identity: weak password policies, missing MFA enforcement, overly broad RBAC
- Observability: diagnostic settings not streaming to Log Analytics/Event Hub/Storage, missing alerts and action groups

For exact injected rules, review `metadata/project_metadata.json -> vulnerabilities[]` in each subproject.
