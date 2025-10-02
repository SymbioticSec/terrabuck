# Azure ARM Template Projects

This directory contains multiple Azure reference projects implemented with Azure Resource Manager (ARM) templates. Each subproject demonstrates a realistic enterprise use case with `main.json`, inputs (`variables.json`), outputs (`outputs.json`), and metadata under `metadata/`.

- Each project folder includes its own detailed `README.md`.
- Metadata: `metadata/project_metadata.json` describes the use case, components, and injected misconfigurations; `component_analysis.json` and label files provide additional context.

## Subprojects

Follow each link to the subproject’s README for details:

- `project_azure-ecommerce-platform-v1/` – Retail eCommerce Platform
- `project_azure-nonprofit-donor-platform/` – Nonprofit Donor Management
- `project_azure-telehealth-platform/` – Telehealth Platform
- `project_azure_construction_bim_platform/` – Construction BIM Platform
- `project_azure_digital_marketing_automation/` – Digital Marketing Automation
- `project_azure_fleet_mgmt_platform/` – Fleet Management Platform
- `project_azure_hr_talent_platform/` – HR Talent Platform
- `project_azure_legal_docmgmt_platform/` – Legal Document Management
- `project_azure_video_streaming_platform/` – Video Streaming Platform
- `project_corporate-intranet-platform/` – Corporate Intranet Platform
- `project_energy-grid-monitoring-scada/` – Energy Grid Monitoring (SCADA)
- `project_fintech_trading_platform/` – Fintech Trading Platform
- `project_healthcare-patient-portal-hipaa/` – HIPAA-Compliant Patient Portal
- `project_iot-manufacturing-mes/` – IoT Manufacturing MES
- `project_restaurant-pos-inventory-mgmt/` – Restaurant POS & Inventory

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

- Storage: containers/blobs publicly accessible, logging disabled, missing private endpoints
- Databases: public network access enabled, no customer-managed keys (CMK), weak auditing/diagnostics
- Compute: unmanaged identities or overprivileged role assignments, plaintext secrets in app settings, missing HTTPS-only
- Networking: NSGs with broad 0.0.0.0/0 rules, public IPs on private tiers, missing DDoS/network policies
- Identity: weak password policies or MFA gaps, overly broad role assignments, missing Key Vault RBAC
- Observability: diagnostic settings not enabled to Log Analytics, no action groups/alerts, missing Defender plans

For exact rules, review `metadata/project_metadata.json -> vulnerabilities[]` in each subproject.
