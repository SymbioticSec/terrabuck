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

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-20.04-amd64-server-*"]
  }
}

# VPC and Networking
resource "aws_vpc" "fleet_management_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-vpc-main"
    Environment = var.environment
    Project     = "fleet-management-gps-tracker"
  }
}

resource "aws_internet_gateway" "fleet_management_igw" {
  vpc_id = aws_vpc.fleet_management_vpc.id
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-igw-main"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.fleet_management_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-subnet-public-1"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.fleet_management_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-subnet-public-2"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.fleet_management_vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-subnet-private-1"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.fleet_management_vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-subnet-private-2"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.fleet_management_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fleet_management_igw.id
  }
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-rt-public"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_rta_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Groups - VULNERABILITY: Open security group
resource "aws_security_group" "dashboard_sg" {
  name_prefix = "fleet-management-dashboard-"
  vpc_id      = aws_vpc.fleet_management_vpc.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # VULNERABILITY: AWS-EC2-NO_PUBLIC_INGRESS_SGR
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # VULNERABILITY: AWS-EC2-NO_PUBLIC_INGRESS_SGR
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-sg-dashboard"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds_sg" {
  name_prefix = "fleet-management-rds-"
  vpc_id      = aws_vpc.fleet_management_vpc.id
  
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-sg-rds"
    Environment = var.environment
  }
}

# IAM Roles and Policies
resource "aws_iam_role" "lambda_execution_role" {
  name = "fleet-management-gps-tracking-system-role-lambda"
  
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
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VULNERABILITY: Weak password policy
resource "aws_iam_account_password_policy" "fleet_password_policy" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers               = true
  require_uppercase_characters   = true
  # require_symbols not set - VULNERABILITY: AWS-IAM-REQUIRE_SYMBOLS_IN_PASSWORDS
  allow_users_to_change_password = true
  max_password_age              = 90
  password_reuse_prevention     = 5
}

# S3 Bucket for tracking data storage
resource "aws_s3_bucket" "tracking_data_storage" {
  bucket = "fleet-management-gps-tracking-system-storage-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-s3-tracking-data"
    Environment = var.environment
    Component   = "tracking_data_storage"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# RDS PostgreSQL Database - VULNERABILITY: Public access enabled
resource "aws_db_subnet_group" "vehicle_db_subnet_group" {
  name       = "fleet-management-vehicle-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-subnet-group-rds"
    Environment = var.environment
  }
}

resource "aws_db_instance" "vehicle_database" {
  identifier     = "fleet-management-gps-tracking-system-rds-vehicle-db"
  engine         = "postgres"
  engine_version = "13.13"
  instance_class = var.db_instance_class
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.vehicle_db_subnet_group.name
  
  publicly_accessible = true  # VULNERABILITY: AWS-RDS-DISABLE_PUBLIC_ACCESS
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-rds-vehicle-database"
    Environment = var.environment
    Component   = "vehicle_database"
  }
}

# CloudWatch Log Group - VULNERABILITY: No customer-managed KMS key
resource "aws_cloudwatch_log_group" "telemetry_processor_logs" {
  name              = "/aws/lambda/fleet-management-gps-tracking-system-lambda-telemetry-processor"
  retention_in_days = 14
  # kms_key_id not set - VULNERABILITY: AWS-CLOUDWATCH-LOG_GROUP_CUSTOMER_KEY
  
  tags = {
    Environment = var.environment
    Component   = "telemetry_processor"
  }
}

# Lambda Function for telemetry processing
resource "aws_lambda_function" "telemetry_processor" {
  filename         = "telemetry_processor.zip"
  function_name    = "fleet-management-gps-tracking-system-lambda-telemetry-processor"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30
  
  environment {
    variables = {
      DB_HOST     = aws_db_instance.vehicle_database.endpoint
      DB_NAME     = var.db_name
      S3_BUCKET   = aws_s3_bucket.tracking_data_storage.bucket
      SNS_TOPIC   = aws_sns_topic.alert_notification.arn
    }
  }
  
  depends_on = [aws_cloudwatch_log_group.telemetry_processor_logs]
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-lambda-telemetry-processor"
    Environment = var.environment
    Component   = "telemetry_processor"
  }
}

# API Gateway for GPS data ingestion - VULNERABILITY: No authorization
resource "aws_api_gateway_rest_api" "gps_data_ingestion" {
  name        = "fleet-management-gps-tracking-system-api-gps-ingestion"
  description = "API Gateway for GPS data ingestion from vehicle IoT devices"
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-api-gps-ingestion"
    Environment = var.environment
    Component   = "gps_data_ingestion"
  }
}

resource "aws_api_gateway_resource" "gps_data_resource" {
  rest_api_id = aws_api_gateway_rest_api.gps_data_ingestion.id
  parent_id   = aws_api_gateway_rest_api.gps_data_ingestion.root_resource_id
  path_part   = "gps-data"
}

resource "aws_api_gateway_method" "gps_data_post" {
  rest_api_id   = aws_api_gateway_rest_api.gps_data_ingestion.id
  resource_id   = aws_api_gateway_resource.gps_data_resource.id
  http_method   = "POST"
  authorization = "NONE"  # VULNERABILITY: AWS-APIGATEWAY-NO_PUBLIC_ACCESS
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.gps_data_ingestion.id
  resource_id = aws_api_gateway_resource.gps_data_resource.id
  http_method = aws_api_gateway_method.gps_data_post.http_method
  
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.telemetry_processor.invoke_arn
}

# SNS Topic for alert notifications - VULNERABILITY: No encryption
resource "aws_sns_topic" "alert_notification" {
  name = "fleet-management-gps-tracking-system-sns-alerts"
  # kms_master_key_id not set - VULNERABILITY: AWS-SNS-ENABLE_TOPIC_ENCRYPTION
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-sns-alert-notification"
    Environment = var.environment
    Component   = "alert_notification"
  }
}

# EC2 Instance for fleet dashboard
resource "aws_instance" "fleet_dashboard" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.dashboard_instance_type
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.dashboard_sg.id]
  
  user_data = base64encode(templatefile("${path.module}/dashboard_userdata.sh", {
    db_host   = aws_db_instance.vehicle_database.endpoint
    db_name   = var.db_name
    s3_bucket = aws_s3_bucket.tracking_data_storage.bucket
  }))
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-ec2-dashboard"
    Environment = var.environment
    Component   = "fleet_dashboard"
  }
}

# CloudTrail for audit logging - VULNERABILITY: No log validation
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "fleet-management-gps-tracking-system-cloudtrail-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-s3-cloudtrail"
    Environment = var.environment
  }
}

resource "aws_cloudtrail" "fleet_audit_trail" {
  name           = "fleet-management-gps-tracking-system-cloudtrail-audit"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket
  # enable_log_file_validation not set - VULNERABILITY: AWS-CLOUDTRAIL-ENABLE_LOG_VALIDATION
  
  tags = {
    Name        = "fleet-management-gps-tracking-system-cloudtrail-audit"
    Environment = var.environment
  }
}