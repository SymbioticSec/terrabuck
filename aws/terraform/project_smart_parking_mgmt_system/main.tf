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

# VPC and Networking
resource "aws_vpc" "smart_parking_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "smart-city-parking-management-system-vpc-main"
    Environment = var.environment
    Project     = "smart_parking_mgmt_system"
  }
}

resource "aws_internet_gateway" "smart_parking_igw" {
  vpc_id = aws_vpc.smart_parking_vpc.id

  tags = {
    Name        = "smart-city-parking-management-system-igw-main"
    Environment = var.environment
    Project     = "smart_parking_mgmt_system"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.smart_parking_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "smart-city-parking-management-system-subnet-public-1"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.smart_parking_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "smart-city-parking-management-system-subnet-public-2"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.smart_parking_vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "smart-city-parking-management-system-subnet-private-1"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.smart_parking_vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "smart-city-parking-management-system-subnet-private-2"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.smart_parking_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.smart_parking_igw.id
  }

  tags = {
    Name        = "smart-city-parking-management-system-rt-public"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_rta_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Groups
resource "aws_security_group" "lambda_sg" {
  name        = "smart-city-parking-management-system-sg-lambda"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.smart_parking_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "smart-city-parking-management-system-sg-lambda"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "smart-city-parking-management-system-sg-rds"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.smart_parking_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  tags = {
    Name        = "smart-city-parking-management-system-sg-rds"
    Environment = var.environment
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "parking_db_subnet_group" {
  name       = "smart-city-parking-management-system-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name        = "smart-city-parking-management-system-db-subnet-group"
    Environment = var.environment
  }
}

# RDS PostgreSQL Instance (parking_database component)
resource "aws_db_instance" "parking_database" {
  identifier     = "smart-city-parking-management-system-rds-main"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.parking_db_subnet_group.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # VULNERABILITY: Performance Insights enabled without customer KMS key
  performance_insights_enabled = true
  # performance_insights_kms_key_id is omitted - uses AWS managed key

  skip_final_snapshot = true

  tags = {
    Name        = "smart-city-parking-management-system-rds-main"
    Environment = var.environment
    Component   = "parking_database"
  }
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_execution_role" {
  name = "smart-city-parking-management-system-lambda-role"

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
    Name        = "smart-city-parking-management-system-lambda-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# CloudWatch Log Groups for Lambda Functions
# VULNERABILITY: Log group without customer KMS key
resource "aws_cloudwatch_log_group" "sensor_processing_logs" {
  name              = "/aws/lambda/smart-city-parking-management-system-lambda-sensor-processing"
  retention_in_days = 14
  # kms_key_id is omitted - uses AWS managed encryption

  tags = {
    Name        = "smart-city-parking-management-system-logs-sensor-processing"
    Environment = var.environment
    Component   = "sensor_data_processing"
  }
}

resource "aws_cloudwatch_log_group" "payment_processing_logs" {
  name              = "/aws/lambda/smart-city-parking-management-system-lambda-payment-processing"
  retention_in_days = 14

  tags = {
    Name        = "smart-city-parking-management-system-logs-payment-processing"
    Environment = var.environment
    Component   = "payment_processing"
  }
}

# Lambda Function for Sensor Data Processing
resource "aws_lambda_function" "sensor_data_processing" {
  filename         = "sensor_processing.zip"
  function_name    = "smart-city-parking-management-system-lambda-sensor-processing"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST = aws_db_instance.parking_database.endpoint
      DB_NAME = var.db_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.sensor_processing_logs]

  tags = {
    Name        = "smart-city-parking-management-system-lambda-sensor-processing"
    Environment = var.environment
    Component   = "sensor_data_processing"
  }
}

# Lambda Function for Payment Processing
resource "aws_lambda_function" "payment_processing" {
  filename         = "payment_processing.zip"
  function_name    = "smart-city-parking-management-system-lambda-payment-processing"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST = aws_db_instance.parking_database.endpoint
      DB_NAME = var.db_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.payment_processing_logs]

  tags = {
    Name        = "smart-city-parking-management-system-lambda-payment-processing"
    Environment = var.environment
    Component   = "payment_processing"
  }
}

# IoT Core Thing Type and Policy (iot_data_ingestion component)
resource "aws_iot_thing_type" "parking_sensor" {
  name = "smart-city-parking-management-system-iot-sensor-type"

  properties {
    description = "Parking sensor device type for smart city parking management"
  }

  tags = {
    Name        = "smart-city-parking-management-system-iot-sensor-type"
    Environment = var.environment
    Component   = "iot_data_ingestion"
  }
}

resource "aws_iot_policy" "parking_sensor_policy" {
  name = "smart-city-parking-management-system-iot-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect",
          "iot:Publish",
          "iot:Subscribe",
          "iot:Receive"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "smart-city-parking-management-system-iot-policy"
    Environment = var.environment
    Component   = "iot_data_ingestion"
  }
}

# API Gateway for Citizen Mobile API
resource "aws_api_gateway_rest_api" "citizen_mobile_api" {
  name        = "smart-city-parking-management-system-api-citizen"
  description = "RESTful API for citizen mobile applications"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "smart-city-parking-management-system-api-citizen"
    Environment = var.environment
    Component   = "citizen_mobile_api"
  }
}

resource "aws_api_gateway_deployment" "citizen_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.citizen_mobile_api.id
  stage_name  = var.api_stage_name

  depends_on = [aws_api_gateway_rest_api.citizen_mobile_api]

  tags = {
    Name        = "smart-city-parking-management-system-api-deployment"
    Environment = var.environment
  }
}

# VULNERABILITY: API Gateway stage without access logging
resource "aws_api_gateway_stage" "citizen_api_stage" {
  deployment_id = aws_api_gateway_deployment.citizen_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.citizen_mobile_api.id
  stage_name    = var.api_stage_name
  
  # access_log_settings block is omitted - no access logging configured

  tags = {
    Name        = "smart-city-parking-management-system-api-stage"
    Environment = var.environment
    Component   = "citizen_mobile_api"
  }
}

# S3 Bucket for Admin Dashboard Hosting
resource "aws_s3_bucket" "admin_dashboard" {
  bucket = "smart-city-parking-management-system-s3-admin-dashboard-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "smart-city-parking-management-system-s3-admin-dashboard"
    Environment = var.environment
    Component   = "admin_dashboard_hosting"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "admin_dashboard_versioning" {
  bucket = aws_s3_bucket.admin_dashboard.id
  versioning_configuration {
    status = "Enabled"
  }
}

# VULNERABILITY: S3 bucket without public access block configuration
# aws_s3_bucket_public_access_block resource is omitted entirely

# CloudFront Distribution for Admin Dashboard
resource "aws_cloudfront_distribution" "admin_dashboard_cdn" {
  origin {
    domain_name = aws_s3_bucket.admin_dashboard.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.admin_dashboard.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.admin_dashboard_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.admin_dashboard.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # VULNERABILITY: Using weak TLS policy
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn           = aws_acm_certificate.admin_dashboard_cert.arn
    minimum_protocol_version      = "TLSv1.0"  # Weak TLS version
    ssl_support_method            = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "smart-city-parking-management-system-cloudfront-admin"
    Environment = var.environment
    Component   = "admin_dashboard_hosting"
  }
}

resource "aws_cloudfront_origin_access_identity" "admin_dashboard_oai" {
  comment = "OAI for smart city parking admin dashboard"
}

# ACM Certificate for CloudFront
resource "aws_acm_certificate" "admin_dashboard_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "smart-city-parking-management-system-acm-cert"
    Environment = var.environment
  }
}

# CloudTrail for Audit Logging
# VULNERABILITY: CloudTrail without customer KMS key
resource "aws_cloudtrail" "parking_system_audit" {
  name           = "smart-city-parking-management-system-cloudtrail-audit"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket
  
  # kms_key_id is omitted - uses AWS managed encryption
  
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true

  tags = {
    Name        = "smart-city-parking-management-system-cloudtrail-audit"
    Environment = var.environment
    Component   = "iot_data_ingestion"
  }
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "smart-city-parking-management-system-s3-cloudtrail-${random_string.cloudtrail_suffix.result}"
  force_destroy = true

  tags = {
    Name        = "smart-city-parking-management-system-s3-cloudtrail"
    Environment = var.environment
  }
}

resource "random_string" "cloudtrail_suffix" {
  length  = 8
  special = false
  upper   = false
}

# VULNERABILITY: IAM Password Policy without symbol requirement
resource "aws_iam_account_password_policy" "parking_system_password_policy" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers               = true
  # require_symbols is omitted - allows passwords without special characters
  allow_users_to_change_password = true
  max_password_age              = 90
  password_reuse_prevention     = 5
}