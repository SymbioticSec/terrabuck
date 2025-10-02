# Fleet Management and GPS Tracking Platform

This Terraform configuration deploys a comprehensive fleet management platform on Google Cloud Platform for real-time vehicle tracking, driver behavior monitoring, and route optimization.

## Architecture Overview

The platform implements an event-driven microservices architecture with the following components:

- **Vehicle Telemetry Ingestion**: Cloud Functions for receiving GPS and sensor data
- **Real-time Processing**: Dataflow for stream processing (configured via IAM)
- **Fleet Database**: Cloud SQL PostgreSQL for operational data
- **Telemetry Data Lake**: Cloud Storage for long-term analytics
- **Fleet Management API**: Compute Engine instance providing REST API
- **Dispatcher Dashboard**: Web application for fleet monitoring
- **Analytics Processing**: Cloud Functions for batch analytics

## Prerequisites

1. Google Cloud Platform account with billing enabled
2. Terraform >= 1.0 installed
3. Google Cloud SDK installed and authenticated
4. Required APIs enabled:
   - Compute Engine API
   - Cloud SQL Admin API
   - Cloud Functions API
   - Cloud Storage API
   - Cloud KMS API
   - Service Networking API

## Deployment Instructions

### 1. Clone and Prepare

```bash
git clone <repository-url>
cd fleet-management-platform
```

### 2. Create Function Source Files

Create the following directory structure and files:

```
functions/
├── telemetry-ingestion/
│   ├── main.py
│   └── requirements.txt
└── analytics-processing/
    ├── main.py
    └── requirements.txt
```

**functions/telemetry-ingestion/main.py:**
```python
import json
from google.cloud import storage

def ingest_telemetry(request):
    """HTTP Cloud Function to ingest vehicle telemetry data."""
    try:
        request_json = request.get_json()
        if request_json and 'vehicle_id' in request_json:
            # Process telemetry data
            return json.dumps({'status': 'success', 'message': 'Telemetry ingested'})
        else:
            return json.dumps({'status': 'error', 'message': 'Invalid payload'}), 400
    except Exception as e:
        return json.dumps({'status': 'error', 'message': str(e)}), 500
```

**functions/telemetry-ingestion/requirements.txt:**
```
google-cloud-storage==2.10.0
```

**functions/analytics-processing/main.py:**
```python
import json
from google.cloud import storage

def process_analytics(event, context):
    """Background Cloud Function to process analytics."""
    try:
        file_name = event['name']
        bucket_name = event['bucket']
        print(f'Processing file: {file_name} from bucket: {bucket_name}')
        # Add analytics processing logic here
        return 'Analytics processed successfully'
    except Exception as e:
        print(f'Error processing analytics: {str(e)}')
        raise
```

**functions/analytics-processing/requirements.txt:**
```
google-cloud-storage==2.10.0
google-cloud-sql==3.4.0
```

### 3. Create Startup Scripts

Create a `scripts/` directory with startup scripts:

**scripts/api-startup.sh:**
```bash
#!/bin/bash
apt-get update
apt-get install -y python3 python3-pip nginx
pip3 install flask gunicorn
# Add API application setup here
systemctl enable nginx
systemctl start nginx
```

**scripts/dashboard-startup.sh:**
```bash
#!/bin/bash
apt-get update
apt-get install -y nginx nodejs npm
# Add dashboard application setup here
systemctl enable nginx
systemctl start nginx
```

### 4. Configure Variables

Create a `terraform.tfvars` file:

```hcl
project_id     = "your-gcp-project-id"
project_number = "your-gcp-project-number"
region         = "us-central1"
zone           = "us-central1-a"
environment    = "prod"
fleet_size     = 500
```

### 5. Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable dataflow.googleapis.com
```

### 6. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 7. Post-Deployment Configuration

After deployment, configure the following:

1. **Database Setup**: Connect to Cloud SQL and create necessary tables
2. **Function Deployment**: The functions will be automatically deployed
3. **Load Balancer**: Configure the load balancer for the dashboard (additional configuration needed)
4. **Monitoring**: Set up Cloud Monitoring dashboards
5. **Dataflow Jobs**: Deploy Dataflow jobs for real-time processing

## Usage

### Telemetry Ingestion

Send vehicle telemetry data to the Cloud Function endpoint:

```bash
curl -X POST [TELEMETRY_FUNCTION_URL] \
  -H "Content-Type: application/json" \
  -d '{
    "vehicle_id": "VEHICLE_001",
    "timestamp": "2024-01-01T12:00:00Z",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "speed": 45.5,
    "fuel_level": 75.2
  }'
```

### API Access

Access the fleet management API at the internal IP of the API instance.

### Dashboard Access

Access the dispatcher dashboard through the configured load balancer.

## Security Considerations

This deployment includes several security features:
- Private subnets for compute resources
- Cloud SQL with private IP and SSL
- KMS encryption for data at rest
- Service accounts with minimal permissions
- VPC firewall rules

## Monitoring and Logging

The platform includes:
- Cloud SQL query logging
- Function execution logs
- VPC flow logs (when enabled)
- Custom metrics for fleet operations

## Scaling

The platform can be scaled by:
- Adjusting Compute Engine instance sizes
- Increasing Cloud SQL capacity
- Configuring auto-scaling for Dataflow jobs
- Adding more Cloud Function instances

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Support

For issues and questions, please refer to the Google Cloud documentation or contact your system administrator.