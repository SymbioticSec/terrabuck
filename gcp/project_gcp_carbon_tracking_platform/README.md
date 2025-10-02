# Corporate Carbon Footprint Tracking Platform

This Terraform configuration deploys a comprehensive platform for enterprises to track, analyze, and report their carbon emissions across multiple facilities and operations.

## Architecture Overview

The platform consists of the following components:

1. **IoT Data Ingestion** - Cloud Functions for processing real-time sensor data
2. **Emissions Data Lake** - Cloud Storage for raw emissions data and historical records
3. **Carbon Calculation Engine** - Compute Engine instances running calculation algorithms
4. **Reporting Database** - Cloud SQL PostgreSQL for carbon metrics and reports
5. **Sustainability Dashboard** - App Engine web application for visualization
6. **Report Generation Service** - Cloud Run containerized service for automated reporting

## Prerequisites

- Google Cloud Platform account with billing enabled
- Terraform >= 1.0 installed
- `gcloud` CLI configured with appropriate permissions
- Docker (for building Cloud Run container images)

## Required GCP APIs

Enable the following APIs in your project:
```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable appengine.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

## Deployment Instructions

1. **Clone and prepare the configuration:**
   ```bash
   git clone <repository-url>
   cd carbon-tracking-platform
   ```

2. **Create function source archive:**
   ```bash
   # Create a simple function source file
   mkdir function-source
   cat > function-source/main.py << 'EOF'
   import json
   from google.cloud import storage

   def ingest_iot_data(request):
       """HTTP Cloud Function to ingest IoT sensor data."""
       try:
           data = request.get_json()
           # Process and store data
           return json.dumps({"status": "success", "message": "Data ingested"})
       except Exception as e:
           return json.dumps({"status": "error", "message": str(e)})
   EOF
   
   cat > function-source/requirements.txt << 'EOF'
   google-cloud-storage==2.10.0
   EOF
   
   cd function-source && zip -r ../function-source.zip . && cd ..
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Create terraform.tfvars:**
   ```bash
   cat > terraform.tfvars << 'EOF'
   project_id = "your-gcp-project-id"
   region     = "us-central1"
   zone       = "us-central1-a"
   environment = "prod"
   company_name = "your-company"
   EOF
   ```

5. **Plan and apply:**
   ```bash
   terraform plan
   terraform apply
   ```

## Post-Deployment Setup

1. **Build and deploy Cloud Run container:**
   ```bash
   # Create a simple report generator
   mkdir report-generator
   cat > report-generator/Dockerfile << 'EOF'
   FROM python:3.9-slim
   WORKDIR /app
   COPY . .
   RUN pip install flask gunicorn psycopg2-binary google-cloud-storage
   CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 app:app
   EOF
   
   # Build and push
   cd report-generator
   gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/report-generator
   ```

2. **Deploy App Engine application:**
   ```bash
   # Create app.yaml for the dashboard
   cat > app.yaml << 'EOF'
   runtime: python39
   service: default
   
   handlers:
   - url: /.*
     script: auto
   EOF
   
   gcloud app deploy
   ```

## Security Considerations

⚠️ **IMPORTANT**: This configuration contains several security vulnerabilities for testing purposes:

- Compute instances have public IP addresses
- Database connection logging is disabled
- Project-wide SSH keys are enabled
- Integrity monitoring is disabled on VMs
- VPC flow logs are disabled on some subnets
- Default service accounts are used
- Database error logging is set to minimal level
- Firewall rules allow all ports internally

**For production use, these vulnerabilities must be addressed.**

## Monitoring and Maintenance

- Monitor Cloud Function execution logs for IoT data ingestion issues
- Set up Cloud SQL backup retention policies
- Configure Cloud Storage lifecycle policies for cost optimization
- Implement proper IAM roles and service accounts
- Enable audit logging for compliance requirements

## Cost Optimization

- Use preemptible instances for non-critical calculation workloads
- Implement Cloud Storage lifecycle policies
- Monitor and optimize Cloud Function execution time
- Consider using Cloud SQL read replicas for reporting queries

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Support

For issues and questions:
- Check GCP documentation for service-specific guidance
- Review Terraform Google provider documentation
- Monitor GCP console for resource status and logs