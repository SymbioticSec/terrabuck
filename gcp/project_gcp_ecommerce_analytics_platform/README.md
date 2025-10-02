# E-commerce Real-time Analytics Platform

This Terraform configuration deploys a comprehensive real-time analytics platform for e-commerce companies on Google Cloud Platform. The platform processes customer behavior data, product interactions, and sales metrics in real-time.

## Architecture Overview

The platform consists of the following components:

1. **Data Ingestion Gateway** (Cloud Run) - Receives clickstream data from web/mobile applications
2. **Event Streaming Pipeline** (Pub/Sub) - Manages real-time event streaming and message queuing
3. **Analytics Processor** (Cloud Functions) - Processes streaming data for real-time analytics
4. **Analytics Database** (Cloud SQL PostgreSQL) - Stores processed analytics data and customer profiles
5. **Data Warehouse** (BigQuery) - Long-term storage for historical data analysis
6. **Dashboard Application** (Compute Engine) - Hosts business intelligence dashboards

## Network Architecture

- **VPC Network**: Single VPC with three subnets
  - Public subnet (10.0.1.0/24) for ingestion gateway
  - Private subnet (10.0.2.0/24) for processing components
  - Data subnet (10.0.3.0/24) for databases
- **Cloud NAT**: Provides internet access for private subnet resources
- **Firewall Rules**: Configured for secure communication between components

## Prerequisites

1. Google Cloud Project with billing enabled
2. Terraform >= 1.0 installed
3. Google Cloud SDK installed and authenticated
4. Required APIs enabled:
   - Compute Engine API
   - Cloud Run API
   - Cloud Functions API
   - Cloud SQL Admin API
   - BigQuery API
   - Pub/Sub API
   - VPC Access API

## Deployment Instructions

1. **Clone and prepare the configuration:**
   ```bash
   git clone <repository-url>
   cd ecommerce-analytics-platform
   ```

2. **Create the function source code archive:**
   ```bash
   # Create a simple analytics processor function
   mkdir -p function-source
   cat > function-source/main.py << 'EOF'
   import json
   import base64
   from google.cloud import bigquery
   from google.cloud import sql

   def process_analytics(event, context):
       """Triggered from a message on a Cloud Pub/Sub topic."""
       pubsub_message = base64.b64decode(event['data']).decode('utf-8')
       data = json.loads(pubsub_message)
       
       # Process the analytics data
       print(f"Processing event: {data}")
       
       # Insert into BigQuery (simplified example)
       # In production, implement proper data processing logic
       
       return 'OK'
   EOF
   
   cat > function-source/requirements.txt << 'EOF'
   google-cloud-bigquery==3.4.0
   google-cloud-sql==0.1.0
   EOF
   
   cd function-source && zip -r ../analytics-processor.zip . && cd ..
   ```

3. **Create dashboard startup script:**
   ```bash
   cat > dashboard-startup.sh << 'EOF'
   #!/bin/bash
   apt-get update
   apt-get install -y nginx python3 python3-pip
   pip3 install flask gunicorn
   
   # Create a simple dashboard application
   cat > /opt/dashboard.py << 'PYEOF'
   from flask import Flask
   app = Flask(__name__)
   
   @app.route('/')
   def dashboard():
       return '<h1>E-commerce Analytics Dashboard</h1><p>Dashboard is running!</p>'
   
   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=8080)
   PYEOF
   
   # Start the dashboard service
   nohup python3 /opt/dashboard.py &
   EOF
   ```

4. **Set up Terraform variables:**
   ```bash
   cat > terraform.tfvars << 'EOF'
   project_id = "your-gcp-project-id"
   region = "us-central1"
   zone = "us-central1-a"
   db_password = "your-secure-database-password"
   admin_email = "admin@yourcompany.com"
   organization_domain = "yourcompany.com"
   EOF
   ```

5. **Deploy the infrastructure:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Post-Deployment Configuration

1. **Configure Cloud Run service:**
   - Deploy your ingestion gateway container image to Google Container Registry
   - Update the Cloud Run service with your custom image

2. **Set up database schema:**
   ```bash
   # Connect to Cloud SQL instance and create tables
   gcloud sql connect e-commerce-real-time-analytics-platform-sql-analytics --user=analytics_user
   ```

3. **Configure BigQuery tables:**
   - The customer_analytics table is created automatically
   - Add additional tables as needed for your analytics requirements

4. **Access the dashboard:**
   - SSH into the dashboard VM or set up a load balancer
   - Configure your BI tools to connect to the dashboard application

## Security Considerations

This deployment includes several security configurations:
- VPC with private subnets for sensitive components
- Cloud SQL with SSL connections
- IAM service accounts with specific permissions
- Firewall rules restricting access
- Shielded VM features for compute instances

## Monitoring and Logging

- Cloud Logging is automatically enabled for all services
- Set up Cloud Monitoring alerts for key metrics
- Configure BigQuery audit logs for data access monitoring

## Cost Optimization

- Cloud Functions scale to zero when not in use
- Cloud Run charges only for actual usage
- Consider using preemptible instances for non-critical workloads
- Set up billing alerts to monitor costs

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Support

For issues and questions:
1. Check the Terraform plan output for any errors
2. Review Google Cloud Console for service-specific logs
3. Ensure all required APIs are enabled
4. Verify IAM permissions for the deployment service account