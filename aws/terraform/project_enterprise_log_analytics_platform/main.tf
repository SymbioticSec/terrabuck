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
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }
}

# VPC and Networking
resource "aws_vpc" "enterprise_log_analytics_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-vpc-main"
    Environment = var.environment
    Project     = "enterprise_log_analytics_platform"
  }
}

resource "aws_internet_gateway" "enterprise_log_analytics_igw" {
  vpc_id = aws_vpc.enterprise_log_analytics_vpc.id

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-igw-main"
    Environment = var.environment
    Project     = "enterprise_log_analytics_platform"
  }
}

# VULNERABILITY: NO_PUBLIC_IP_SUBNET - Public subnet with auto-assign public IP
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.enterprise_log_analytics_vpc.id
  cidr_block              = var.public_subnet_cidr_az1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-subnet-public-az1"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "private_subnet_az1" {
  vpc_id            = aws_vpc.enterprise_log_analytics_vpc.id
  cidr_block        = var.private_subnet_cidr_az1
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-subnet-private-az1"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_subnet" "data_subnet_az1" {
  vpc_id            = aws_vpc.enterprise_log_analytics_vpc.id
  cidr_block        = var.data_subnet_cidr_az1
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-subnet-data-az1"
    Environment = var.environment
    Type        = "data"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.enterprise_log_analytics_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.enterprise_log_analytics_igw.id
  }

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-rt-public"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Groups
resource "aws_security_group" "api_gateway_sg" {
  name_prefix = "enterprise-log-analytics-api-gateway-"
  vpc_id      = aws_vpc.enterprise_log_analytics_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-sg-api-gateway"
    Environment = var.environment
  }
}

resource "aws_security_group" "dashboard_sg" {
  name_prefix = "enterprise-log-analytics-dashboard-"
  vpc_id      = aws_vpc.enterprise_log_analytics_vpc.id

  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-sg-dashboard"
    Environment = var.environment
  }
}

# VULNERABILITY: LOG_GROUP_CUSTOMER_KEY - CloudWatch log group without customer-managed KMS key
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/enterprise-log-analytics"
  retention_in_days = 30

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-logs-api-gateway"
    Environment = var.environment
  }
}

# API Gateway (log_ingestion_api component)
resource "aws_api_gateway_rest_api" "log_ingestion_api" {
  name        = "enterprise-log-analytics-and-monitoring-platform-api-gateway-ingestion"
  description = "API for ingesting logs from enterprise applications"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-api-gateway-ingestion"
    Environment = var.environment
    Component   = "log_ingestion_api"
  }
}

resource "aws_api_gateway_resource" "logs_resource" {
  rest_api_id = aws_api_gateway_rest_api.log_ingestion_api.id
  parent_id   = aws_api_gateway_rest_api.log_ingestion_api.root_resource_id
  path_part   = "logs"
}

resource "aws_api_gateway_method" "post_logs" {
  rest_api_id   = aws_api_gateway_rest_api.log_ingestion_api.id
  resource_id   = aws_api_gateway_resource.logs_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.log_ingestion_api.id
  resource_id = aws_api_gateway_resource.logs_resource.id
  http_method = aws_api_gateway_method.post_logs.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.log_processing_pipeline.invoke_arn
}

# VULNERABILITY: ENABLE_ACCESS_LOGGING - API Gateway stage without access logging
resource "aws_api_gateway_deployment" "log_ingestion_deployment" {
  depends_on = [
    aws_api_gateway_method.post_logs,
    aws_api_gateway_integration.lambda_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.log_ingestion_api.id
  stage_name  = var.environment
}

# Lambda Function (log_processing_pipeline component)
resource "aws_iam_role" "lambda_execution_role" {
  name = "enterprise-log-analytics-lambda-execution-role"

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
    Name        = "enterprise-log-analytics-and-monitoring-platform-role-lambda"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "enterprise-log-analytics-lambda-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.processed_logs_storage.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "es:ESHttpPost",
          "es:ESHttpPut"
        ]
        Resource = "${aws_elasticsearch_domain.log_search_database.arn}/*"
      }
    ]
  })
}

resource "aws_lambda_function" "log_processing_pipeline" {
  filename         = "log_processor.zip"
  function_name    = "enterprise-log-analytics-and-monitoring-platform-lambda-processor"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.processed_logs_storage.bucket
      ES_ENDPOINT = aws_elasticsearch_domain.log_search_database.endpoint
    }
  }

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-lambda-processor"
    Environment = var.environment
    Component   = "log_processing_pipeline"
  }
}

# VULNERABILITY: RESTRICT_SOURCE_ARN - Lambda permission without source ARN restriction
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_processing_pipeline.function_name
  principal     = "apigateway.amazonaws.com"
}

# S3 Bucket (processed_logs_storage component)
resource "aws_s3_bucket" "processed_logs_storage" {
  bucket = "enterprise-log-analytics-and-monitoring-platform-s3-storage-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-s3-storage"
    Environment = var.environment
    Component   = "processed_logs_storage"
  }
}

resource "aws_s3_bucket_versioning" "processed_logs_versioning" {
  bucket = aws_s3_bucket.processed_logs_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "processed_logs_lifecycle" {
  bucket = aws_s3_bucket.processed_logs_storage.id

  rule {
    id     = "log_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# VULNERABILITY: ENABLE_DOMAIN_ENCRYPTION & ENABLE_DOMAIN_LOGGING - Elasticsearch without encryption and logging
resource "aws_elasticsearch_domain" "log_search_database" {
  domain_name           = "enterprise-log-analytics-es"
  elasticsearch_version = "7.10"

  cluster_config {
    instance_type  = var.elasticsearch_instance_type
    instance_count = 2
  }

  vpc_options {
    subnet_ids         = [aws_subnet.data_subnet_az1.id]
    security_group_ids = [aws_security_group.elasticsearch_sg.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 20
    volume_type = "gp2"
  }

  encrypt_at_rest {
    enabled = false
  }

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-elasticsearch-search"
    Environment = var.environment
    Component   = "log_search_database"
  }
}

resource "aws_security_group" "elasticsearch_sg" {
  name_prefix = "enterprise-log-analytics-elasticsearch-"
  vpc_id      = aws_vpc.enterprise_log_analytics_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-sg-elasticsearch"
    Environment = var.environment
  }
}

# VULNERABILITY: TOPIC_ENCRYPTION_WITH_CMK - SNS topic using AWS-managed key
resource "aws_sns_topic" "alert_notification_system" {
  name              = "enterprise-log-analytics-and-monitoring-platform-sns-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-sns-alerts"
    Environment = var.environment
    Component   = "alert_notification_system"
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alert_notification_system.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# EC2 Instance for Dashboard (log_analytics_dashboard component)
resource "aws_iam_role" "dashboard_role" {
  name = "enterprise-log-analytics-dashboard-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-role-dashboard"
    Environment = var.environment
  }
}

resource "aws_iam_instance_profile" "dashboard_profile" {
  name = "enterprise-log-analytics-dashboard-profile"
  role = aws_iam_role.dashboard_role.name
}

resource "aws_instance" "log_analytics_dashboard" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.dashboard_instance_type
  subnet_id              = aws_subnet.private_subnet_az1.id
  vpc_security_group_ids = [aws_security_group.dashboard_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.dashboard_profile.name

  user_data = base64encode(templatefile("${path.module}/dashboard_userdata.sh", {
    elasticsearch_endpoint = aws_elasticsearch_domain.log_search_database.endpoint
  }))

  tags = {
    Name        = "enterprise-log-analytics-and-monitoring-platform-ec2-dashboard"
    Environment = var.environment
    Component   = "log_analytics_dashboard"
  }
}