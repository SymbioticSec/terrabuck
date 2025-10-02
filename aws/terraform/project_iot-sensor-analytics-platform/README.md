# Smart Manufacturing IoT Analytics Platform

A production-grade IoT platform for manufacturing facilities that collects sensor data from production lines, processes it in real-time for anomaly detection, and provides analytics dashboards for operations teams.

## Architecture Overview

This platform implements an event-driven data pipeline that handles:
- Temperature, vibration, and pressure sensors from multiple production lines
- Real-time anomaly detection and alerting
- Time-series data storage and analytics
- Compliance reporting and data archival
- RESTful API for dashboard integration

## Components

### 1. IoT Data Ingestion (AWS IoT Core)
- Secure MQTT endpoint for sensor data collection
- Device authentication using certificates
- Message routing to downstream processing

### 2. Stream Processing (AWS Kinesis Data Streams)
- Real-time data streaming and buffering
- Handles 10,000+ sensor readings per minute
- Scalable shard-based architecture

### 3. Anomaly Detection (AWS Lambda)
- Real-time processing for anomaly detection
- Statistical analysis and threshold alerting
- VPC isolation for security

### 4. Time Series Database (AWS TimeStream)
- Optimized storage for time-series sensor data
- Automatic data lifecycle management
- High-performance queries for analytics

### 5. Analytics API (AWS API Gateway)
- RESTful API for dashboard queries
- Historical data retrieval
- Rate limiting and authentication

### 6. Compliance Storage (AWS S3)
- Long-term archival storage
- Regulatory compliance features
- Immutable data retention

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Python 3.9+ for Lambda function development

## Deployment Instructions

### 1. Clone and Initialize

```bash
git clone <repository-url>
cd smart-manufacturing-iot-analytics-platform
terraform init
```

### 2. Configure Variables

Create a `terraform.tfvars` file:

```hcl
aws_region = "us-east-1"
environment = "prod"
project_name = "smart-manufacturing-iot-analytics-platform"
vpc_cidr = "10.0.0.0/16"
kinesis_shard_count = 2
```

### 3. Create Lambda Deployment Package

```bash
# Create a dummy Lambda function package
mkdir -p lambda_src
cat > lambda_src/index.py << 'EOF'
import json
import boto3
import os
from datetime import datetime

def handler(event, context):
    """
    Anomaly detection Lambda function for manufacturing sensor data
    """
    timestream_client = boto3.client('timestream-write')
    
    for record in event['Records']:
        # Decode Kinesis data
        payload = json.loads(base64.b64decode(record['kinesis']['data']))
        
        # Simple anomaly detection logic
        sensor_value = payload.get('value', 0)
        sensor_type = payload.get('type', 'unknown')
        
        # Define thresholds
        thresholds = {
            'temperature': {'min': 10, 'max': 80},
            'vibration': {'min': 0, 'max': 100},
            'pressure': {'min': 0, 'max': 200}
        }
        
        is_anomaly = False
        if sensor_type in thresholds:
            threshold = thresholds[sensor_type]
            if sensor_value < threshold['min'] or sensor_value > threshold['max']:
                is_anomaly = True
        
        # Write to TimeStream
        records = [{
            'Dimensions': [
                {'Name': 'sensor_id', 'Value': payload.get('sensor_id', 'unknown')},
                {'Name': 'production_line', 'Value': payload.get('production_line', 'line1')},
                {'Name': 'sensor_type', 'Value': sensor_type}
            ],
            'MeasureName': 'sensor_reading',
            'MeasureValue': str(sensor_value),
            'MeasureValueType': 'DOUBLE',
            'Time': str(int(datetime.now().timestamp() * 1000))
        }]
        
        if is_anomaly:
            records.append({
                'Dimensions': [
                    {'Name': 'sensor_id', 'Value': payload.get('sensor_id', 'unknown')},
                    {'Name': 'production_line', 'Value': payload.get('production_line', 'line1')},
                    {'Name': 'alert_type', 'Value': 'threshold_exceeded'}
                ],
                'MeasureName': 'anomaly_alert',
                'MeasureValue': '1',
                'MeasureValueType': 'BIGINT',
                'Time': str(int(datetime.now().timestamp() * 1000))
            })
        
        try:
            timestream_client.write_records(
                DatabaseName=os.environ['TIMESTREAM_DATABASE'],
                TableName=os.environ['TIMESTREAM_TABLE'],
                Records=records
            )
        except Exception as e:
            print(f"Error writing to TimeStream: {str(e)}")
    
    return {'statusCode': 200, 'body': json.dumps('Processing complete')}
EOF

cd lambda_src
zip -r ../anomaly_detection.zip .
cd ..
```

### 4. Deploy Infrastructure

```bash
terraform plan
terraform apply
```

### 5. Verify Deployment

```bash
# Check IoT Core setup
aws iot list-thing-types

# Check Kinesis stream
aws kinesis describe-stream --stream-name smart-manufacturing-iot-analytics-platform-sensor-data-stream

# Check Lambda function
aws lambda get-function --function-name smart-manufacturing-iot-analytics-platform-anomaly-detection

# Check TimeStream database
aws timestream-write describe-database --database-name smart_manufacturing_iot_analytics_platform_sensor_database
```

## Usage

### Sending Sensor Data

Use AWS IoT Device SDK to send data to the MQTT topic:

```python
import json
from awsiot import mqtt_connection_builder
from awscrt import io, mqtt

# Configure connection
event_loop_group = io.EventLoopGroup(1)
host_resolver = io.DefaultHostResolver(event_loop_group)
client_bootstrap = io.ClientBootstrap(event_loop_group, host_resolver)

mqtt_connection = mqtt_connection_builder.mtls_from_path(
    endpoint="your-iot-endpoint.amazonaws.com",
    cert_filepath="path/to/certificate.pem.crt",
    pri_key_filepath="path/to/private.pem.key",
    client_bootstrap=client_bootstrap,
    ca_filepath="path/to/Amazon-root-CA-1.pem",
    client_id="sensor-001"
)

# Send sensor data
sensor_data = {
    "sensor_id": "temp-001",
    "production_line": "line1",
    "type": "temperature",
    "value": 75.5,
    "timestamp": "2024-01-01T12:00:00Z"
}

mqtt_connection.publish(
    topic="manufacturing/sensors/temp-001/data",
    payload=json.dumps(sensor_data),
    qos=mqtt.QoS.AT_LEAST_ONCE
)
```

### Querying Analytics API

```bash
# Get analytics data
curl -X GET "https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/analytics"
```

### Querying TimeStream Data

```sql
SELECT sensor_id, production_line, sensor_type, 
       AVG(measure_value::double) as avg_value,
       COUNT(*) as reading_count
FROM "smart_manufacturing_iot_analytics_platform_sensor_database"."sensor_readings"
WHERE time between ago(1h) and now()
GROUP BY sensor_id, production_line, sensor_type
ORDER BY time DESC
```

## Monitoring and Maintenance

### CloudWatch Metrics
- Monitor Lambda function execution and errors
- Track Kinesis stream throughput and iterator age
- Monitor TimeStream ingestion rates

### Alerts
- Set up CloudWatch alarms for anomaly detection failures
- Monitor API Gateway error rates and latency
- Track S3 storage costs and usage

### Backup and Recovery
- TimeStream automatic backups are configured
- S3 compliance data has lifecycle policies
- Lambda functions are version controlled

## Security Considerations

- IoT devices use certificate-based authentication
- Lambda functions run in private subnets
- All data is encrypted in transit and at rest
- IAM roles follow least privilege principle
- API Gateway includes rate limiting

## Cost Optimization

- TimeStream retention policies minimize storage costs
- Kinesis shards can be adjusted based on throughput
- Lambda functions use appropriate memory allocation
- S3 lifecycle policies archive old compliance data

## Troubleshooting

### Common Issues

1. **Lambda timeout errors**: Increase timeout or optimize function code
2. **Kinesis shard iterator expired**: Increase retention period or processing speed
3. **TimeStream throttling**: Implement exponential backoff in Lambda
4. **IoT connection issues**: Verify certificates and policies

### Logs Location
- Lambda logs: CloudWatch Logs `/aws/lambda/function-name`
- API Gateway logs: CloudWatch Logs (if access logging enabled)
- IoT Core logs: CloudWatch Logs (if logging enabled)

## Support

For issues and questions:
1. Check CloudWatch logs for error details
2. Verify IAM permissions for all services
3. Ensure network connectivity between VPC resources
4. Review AWS service limits and quotas