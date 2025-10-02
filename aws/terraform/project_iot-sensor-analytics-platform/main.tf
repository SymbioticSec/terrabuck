terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Public"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Private"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-lambda-"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-lambda-sg"
    Environment = var.environment
  }
}

# IoT Core Components
resource "aws_iot_thing_type" "sensor" {
  name = "${var.project_name}-sensor-type"

  properties {
    description = "Manufacturing sensor device type"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iot_policy" "sensor_policy" {
  name = "${var.project_name}-sensor-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect",
          "iot:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iot_topic_rule" "sensor_data" {
  name        = replace("${var.project_name}_sensor_data_rule", "-", "_")
  description = "Route sensor data to Kinesis stream"
  enabled     = true
  sql         = "SELECT * FROM 'manufacturing/sensors/+/data'"
  sql_version = "2016-03-23"

  kinesis {
    stream_name = aws_kinesis_stream.sensor_data.name
    role_arn    = aws_iam_role.iot_kinesis_role.arn
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Kinesis Data Stream
resource "aws_kinesis_stream" "sensor_data" {
  name             = "${var.project_name}-sensor-data-stream"
  shard_count      = var.kinesis_shard_count
  retention_period = 24

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda Functions
resource "aws_lambda_function" "anomaly_detection" {
  filename         = "anomaly_detection.zip"
  function_name    = "${var.project_name}-anomaly-detection"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      TIMESTREAM_DATABASE = aws_timestreamwrite_database.sensor_data.database_name
      TIMESTREAM_TABLE    = aws_timestreamwrite_table.sensor_readings.table_name
      DATABASE_PASSWORD   = "hardcoded_password_123"
      API_KEY            = "sk-1234567890abcdef"
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = aws_kinesis_stream.sensor_data.arn
  function_name     = aws_lambda_function.anomaly_detection.arn
  starting_position = "LATEST"
  batch_size        = 100
}

# TimeStream Database
resource "aws_timestreamwrite_database" "sensor_data" {
  database_name = replace("${var.project_name}_sensor_database", "-", "_")

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_timestreamwrite_table" "sensor_readings" {
  database_name = aws_timestreamwrite_database.sensor_data.database_name
  table_name    = "sensor_readings"

  retention_properties {
    memory_store_retention_period_in_hours  = 12
    magnetic_store_retention_period_in_days = 365
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "analytics_api" {
  name        = "${var.project_name}-analytics-api"
  description = "Analytics API for manufacturing sensor data"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_api_gateway_deployment" "analytics_api" {
  rest_api_id = aws_api_gateway_rest_api.analytics_api.id
  stage_name  = var.environment

  depends_on = [aws_api_gateway_method.analytics_method]
}

resource "aws_api_gateway_resource" "analytics_resource" {
  rest_api_id = aws_api_gateway_rest_api.analytics_api.id
  parent_id   = aws_api_gateway_rest_api.analytics_api.root_resource_id
  path_part   = "analytics"
}

resource "aws_api_gateway_method" "analytics_method" {
  rest_api_id   = aws_api_gateway_rest_api.analytics_api.id
  resource_id   = aws_api_gateway_resource.analytics_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# S3 Buckets
resource "aws_s3_bucket" "compliance_storage" {
  bucket = "${var.project_name}-compliance-storage-${random_id.bucket_suffix.hex}"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "Compliance"
  }
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${var.project_name}-cloudtrail-logs-${random_id.bucket_suffix.hex}"
  acl    = "public-read"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "CloudTrail"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# CloudTrail
resource "aws_cloudtrail" "main" {
  name           = "${var.project_name}-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Roles and Policies
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role" "iot_kinesis_role" {
  name = "${var.project_name}-iot-kinesis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_group" "developers" {
  name = "${var.project_name}-developers"
}

resource "aws_iam_role_policy" "lambda_timestream_policy" {
  name = "${var.project_name}-lambda-timestream-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "timestream:WriteRecords",
          "timestream:DescribeEndpoints"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_kinesis_policy" {
  name = "${var.project_name}-iot-kinesis-policy"
  role = aws_iam_role.iot_kinesis_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = aws_kinesis_stream.sensor_data.arn
      }
    ]
  })
}