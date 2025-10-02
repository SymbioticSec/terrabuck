# Smart Manufacturing IoT Analytics Platform

A production-ready IoT platform for manufacturing facilities to collect, process, and analyze sensor data from production lines. This CloudFormation template deploys a complete event-driven data pipeline that ingests real-time temperature, pressure, and vibration data from industrial sensors, processes it for anomaly detection, and provides dashboards for plant managers.

## Architecture Overview

The platform implements an event-driven architecture with the following components:

- **IoT Core**: Secure MQTT endpoint for sensor data ingestion
- **Kinesis Data Streams**: Real-time data streaming and processing
- **Lambda Functions**: Serverless anomaly detection processing
- **TimeStream**: Time-series database for historical data storage
- **EC2 Auto Scaling**: Grafana dashboard hosting with load balancing
- **SNS/SQS**: Alert notification system for maintenance teams

## Prerequisites

Before deploying this template, ensure you have:

1. **AWS CLI configured** with appropriate permissions
2. **EC2 Key Pair** created in your target region
3. **CloudFormation permissions** for all services used
4. **VPC quota** available (this creates a new VPC)

## Deployment Instructions

### Step 1: Clone and Prepare

```bash
git clone <repository-url>
cd smart-manufacturing-iot-platform
```

### Step 2: Deploy the CloudFormation Stack

```bash
aws cloudformation create-stack \
  --stack-name smart-manufacturing-iot-platform \
  --template-body file://main.yaml \
  --parameters ParameterKey=KeyPairName,ParameterValue=your-key-pair-name \
               ParameterKey=Environment,ParameterValue=production \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Step 3: Monitor Deployment

```bash
aws cloudformation describe-stacks \
  --stack-name smart-manufacturing-iot-platform \
  --query 'Stacks[0].StackStatus'
```

### Step 4: Retrieve Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name smart-manufacturing-iot-platform \
  --query 'Stacks[0].Outputs'
```

## Configuration Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `Environment` | Deployment environment | `production` | No |
| `ProjectName` | Project name for resources | `smart-manufacturing-iot-analytics-platform` | No |
| `VpcCidr` | VPC CIDR block | `10.0.0.0/16` | No |
| `InstanceType` | EC2 instance type for dashboard | `t3.medium` | No |
| `KeyPairName` | EC2 Key Pair name | - | **Yes** |

## Post-Deployment Configuration

### 1. Configure IoT Devices

After deployment, configure your IoT sensors to connect to the IoT Core endpoint:

```bash
# Get IoT endpoint
aws iot describe-endpoint --endpoint-type iot:Data-ATS
```

### 2. Access Grafana Dashboard

The Grafana dashboard will be available at the ALB DNS name (check stack outputs):

```bash
# Get dashboard URL from outputs
aws cloudformation describe-stacks \
  --stack-name smart-manufacturing-iot-platform \
  --query 'Stacks[0].Outputs[?OutputKey==`DashboardURL`].OutputValue' \
  --output text
```

Default Grafana credentials:
- Username: `admin`
- Password: `admin` (change on first login)

### 3. Configure TimeStream Data Source

In Grafana, add TimeStream as a data source:
1. Go to Configuration → Data Sources
2. Add TimeStream data source
3. Use the database and table names from stack outputs

### 4. Set Up Alert Subscriptions

Subscribe to the SNS topic for alert notifications:

```bash
# Get SNS topic ARN from outputs
SNS_TOPIC_ARN=$(aws cloudformation describe-stacks \
  --stack-name smart-manufacturing-iot-platform \
  --query 'Stacks[0].Outputs[?OutputKey==`AlertTopicArn`].OutputValue' \
  --output text)

# Subscribe email to alerts
aws sns subscribe \
  --topic-arn $SNS_TOPIC_ARN \
  --protocol email \
  --notification-endpoint your-email@company.com
```

## IoT Device Integration

### MQTT Topic Structure

Sensors should publish data to the following topic structure:
```
manufacturing/facility/{facility_id}/line/{line_id}/sensor/{sensor_id}
```

### Message Format

```json
{
  "timestamp": "2023-12-07T10:30:00Z",
  "facility_id": "facility_001",
  "line_id": "line_A",
  "sensor_id": "temp_001",
  "sensor_type": "temperature",
  "value": 75.5,
  "unit": "celsius",
  "location": {
    "x": 10.5,
    "y": 20.3,
    "zone": "assembly"
  }
}
```

### Device Certificate Setup

1. Create IoT Thing:
```bash
aws iot create-thing --thing-name sensor-001 --thing-type-name smart-manufacturing-iot-analytics-platform-sensor-thing-type
```

2. Create and attach certificate:
```bash
aws iot create-keys-and-certificate --set-as-active \
  --certificate-pem-outfile cert.pem \
  --private-key-outfile private.key \
  --public-key-outfile public.key
```

## Monitoring and Troubleshooting

### CloudWatch Logs

Monitor the following log groups:
- `/aws/lambda/smart-manufacturing-iot-analytics-platform-anomaly-detection`
- `/aws/kinesis/smart-manufacturing-iot-analytics-platform-sensor-data-stream`

### Key Metrics to Monitor

- **Kinesis**: IncomingRecords, OutgoingRecords
- **Lambda**: Duration, Errors, Throttles
- **TimeStream**: UserErrors, SystemErrors
- **EC2**: CPUUtilization, NetworkIn/Out

### Common Issues

1. **IoT devices can't connect**: Check device certificates and IoT policies
2. **Lambda timeouts**: Increase timeout or optimize anomaly detection code
3. **Dashboard not accessible**: Check security group rules and ALB health checks
4. **Missing data in TimeStream**: