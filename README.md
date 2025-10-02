# TerraBuck - Vulnerable Infrastructure as Code (IaC) Templates

Intentionally vulnerable Infrastructure-as-Code (IaC) templates for education, testing, and benchmarking of security tooling across AWS, Azure, and GCP. This repository provides realistic, intentionally unsafe examples you can scan, analyze, and use to demo security tooling and remediation workflows.

## Purpose
- Provide realistic but unsafe IaC examples to learn, detect, and remediate misconfigurations.
- Enable tooling comparisons (SAST, IaC scanners, policy-as-code) and demo pipelines.
- Serve as a lab for secure-by-default patterns and regression testing.

## Repository Structure
- `aws/cloudformation/` and `aws/terraform/`: CloudFormation and Terraform samples for AWS.
- `azure/arm/` and `azure/terraform/`: ARM and Terraform samples for Azure.
- `gcp/`: Terraform samples for GCP.

## Responsible Use
- These templates are intentionally insecure. Do NOT deploy to production.
- Use in isolated, disposable accounts/projects and clean up resources promptly.
- You are responsible for usage.

## Project Layout & Conventions
Each `project_*` directory is self-contained and follows provider-specific conventions:

- AWS Terraform / GCP Terraform / Azure Terraform projects
  - IaC files: `*.tf`
  - Metadata: `metadata/` with:
    - `component_analysis.json`: High-level components, dependencies, and purpose.
    - `labels.json`: Project labels (e.g., security posture, counts by severity/type).
    - `label_summary.json`: Aggregated label rollups when applicable.
    - `project_metadata.json`: Project descriptor, ID, category, and context.
 
- AWS CloudFormation projects
  - CloudFormation templates (e.g., `*.yaml`, `*.yml`, or `*.json` depending on sample)
  - Metadata: `metadata/` containing the four JSON files listed above.
 
- Azure ARM projects
  - ARM template files at project root: `main.json`, `variables.json`, `outputs.json` (kept at root by convention).
  - Metadata: `metadata/` containing the four JSON files listed above.

Example (abbreviated):
```text
aws/terraform/
  project_example/
    main.tf
    variables.tf
    outputs.tf
    metadata/
      component_analysis.json
      labels.json
      label_summary.json
      project_metadata.json
```
## Working With Metadata
The `metadata/` folder is intended to support analysis, labeling, and automation around each project:

- `component_analysis.json`: Describes logical components, their purposes, and inter-dependencies.
- `labels.json`: Provides structured labels such as severity counts, risk categories, and realism/complexity scores.
- `label_summary.json`: Summarizes labels across categories to ease reporting and dashboards.
- `project_metadata.json`: Contextual information about the project (ID, cloud, language, category, etc.).

  These files are useful for:

  - Comparing scanner outputs vs. expected risk profiles.
  - Building demo dashboards or analytics notebooks.
  - Driving CI gates and policy-as-code evaluations.
 
 ## Security Notice
 This repository is intentionally unsafe. Do not run these templates against production subscriptions/accounts/projects. If you find an issue that unintentionally exposes sensitive data, please open a private report with minimal details and we will respond promptly.
 
 ## Disclaimer
 This repository is for educational and testing purposes only. You are solely responsible for how you use these templates.
