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
  
  default_tags {
    tags = {
      Project     = "fintech-trading-platform"
      Environment = var.environment
      Owner       = "trading-team"
      CostCenter  = "trading-operations"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }
}

# VPC and Networking
resource "aws_vpc" "real_time_trading_platform_vpc_main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "real-time-trading-platform-vpc-main"
  }
}

resource "aws_internet_gateway" "real_time_trading_platform_igw_main" {
  vpc_id = aws_vpc.real_time_trading_platform_vpc_main.id
  
  tags = {
    Name = "real-time-trading-platform-igw-main"
  }
}

resource "aws_subnet" "real_time_trading_platform_subnet_public" {
  vpc_id                  = aws_vpc.real_time_trading_platform_vpc_main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "real-time-trading-platform-subnet-public"
    Type = "public_dmz"
  }
}

resource "aws_subnet" "real_time_trading_platform_subnet_private_app" {
  vpc_id            = aws_vpc.real_time_trading_platform_vpc_main.id
  cidr_block        = var.private_app_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name = "real-time-trading-platform-subnet-private-app"
    Type = "private_application"
  }
}

resource "aws_subnet" "real_time_trading_platform_subnet_private_data" {
  vpc_id            = aws_vpc.real_time_trading_platform_vpc_main.id
  cidr_block        = var.private_data_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  
  tags = {
    Name = "real-time-trading-platform-subnet-private-data"
    Type = "private_data"
  }
}

resource "aws_route_table" "real_time_trading_platform_rt_public" {
  vpc_id = aws_vpc.real_time_trading_platform_vpc_main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.real_time_trading_platform_igw_main.id
  }
  
  tags = {
    Name = "real-time-trading-platform-rt-public"
  }
}

resource "aws_route_table_association" "real_time_trading_platform_rta_public" {
  subnet_id      = aws_subnet.real_time_trading_platform_subnet_public.id
  route_table_id = aws_route_table.real_time_trading_platform_rt_public.id
}

# Security Groups with vulnerabilities
resource "aws_security_group" "real_time_trading_platform_sg_trading_engine" {
  name_prefix = "real-time-trading-platform-sg-trading-engine"
  vpc_id      = aws_vpc.real_time_trading_platform_vpc_main.id
  
  # VULNERABILITY: AWS-EC2-NO_PUBLIC_INGRESS_SGR - Overly permissive SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "real-time-trading-platform-sg-trading-engine"
  }
}

resource "aws_security_group" "real_time_trading_platform_sg_database" {
  name_prefix = "real-time-trading-platform-sg-database"
  vpc_id      = aws_vpc.real_time_trading_platform_vpc_main.id
  
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.real_time_trading_platform_sg_trading_engine.id]
  }
  
  tags = {
    Name = "real-time-trading-platform-sg-database"
  }
}

# KMS Key with vulnerability
resource "aws_kms_key" "real_time_trading_platform_kms_database" {
  description         = "KMS key for trading platform database encryption"
  enable_key_rotation = false  # VULNERABILITY: AWS-KMS-AUTO_ROTATE_KEYS
  
  tags = {
    Name = "real-time-trading-platform-kms-database"
  }
}

resource "aws_kms_alias" "real_time_trading_platform_kms_alias_database" {
  name          = "alias/real-time-trading-platform-database"
  target_key_id = aws_kms_key.real_time_trading_platform_kms_database.key_id
}

# RDS Database with vulnerability
resource "aws_db_subnet_group" "real_time_trading_platform_db_subnet_group" {
  name       = "real-time-trading-platform-db-subnet-group"
  subnet_ids = [aws_subnet.real_time_trading_platform_subnet_private_data.id, aws_subnet.real_time_trading_platform_subnet_private_app.id]
  
  tags = {
    Name = "real-time-trading-platform-db-subnet-group"
  }
}

resource "aws_db_instance" "real_time_trading_platform_rds_trade_database" {
  identifier             = "real-time-trading-platform-trade-db"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = var.db_instance_class
  allocated_storage      = 100
  storage_encrypted      = true
  kms_key_id            = aws_kms_key.real_time_trading_platform_kms_database.arn
  
  db_name  = "trading_platform"
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.real_time_trading_platform_sg_database.id]
  db_subnet_group_name   = aws_db_subnet_group.real_time_trading_platform_db_subnet_group.name
  
  backup_retention_period = 1  # VULNERABILITY: AWS-RDS-SPECIFY_BACKUP_RETENTION
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  
  tags = {
    Name = "real-time-trading-platform-rds-trade-database"
  }
}

# EC2 Instances for Trading Engine
resource "aws_instance" "real_time_trading_platform_ec2_trading_engine" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.trading_engine_instance_type
  subnet_id              = aws_subnet.real_time_trading_platform_subnet_private_app.id
  vpc_security_group_ids = [aws_security_group.real_time_trading_platform_sg_trading_engine.id]
  iam_instance_profile   = aws_iam_instance_profile.real_time_trading_platform_profile_trading_engine.name
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_endpoint = aws_db_instance.real_time_trading_platform_rds_trade_database.endpoint
  }))
  
  tags = {
    Name = "real-time-trading-platform-ec2-trading-engine-${count.index + 1}"
    Role = "trading-engine"
  }
}

# IAM Roles with vulnerabilities
resource "aws_iam_role" "real_time_trading_platform_role_trading_engine" {
  name = "real-time-trading-platform-role-trading-engine"
  
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
    Name = "real-time-trading-platform-role-trading-engine"
  }
}

resource "aws_iam_policy" "real_time_trading_platform_policy_s3_access" {
  name = "real-time-trading-platform-policy-s3-access"
  
  # VULNERABILITY: AWS-IAM-LIMIT_S3_FULL_ACCESS
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "real_time_trading_platform_attach_s3_policy" {
  role       = aws_iam_role.real_time_trading_platform_role_trading_engine.name
  policy_arn = aws_iam_policy.real_time_trading_platform_policy_s3_access.arn
}

resource "aws_iam_instance_profile" "real_time_trading_platform_profile_trading_engine" {
  name = "real-time-trading-platform-profile-trading-engine"
  role = aws_iam_role.real_time_trading_platform_role_trading_engine.name
}

# Lambda Role for Risk Analytics
resource "aws_iam_role" "real_time_trading_platform_role_lambda_risk" {
  name = "real-time-trading-platform-role-lambda-risk"
  
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
}

resource "aws_iam_role_policy_attachment" "real_time_trading_platform_lambda_basic" {
  role       = aws_iam_role.real_time_trading_platform_role_lambda_risk.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Functions for Risk Analytics
resource "aws_lambda_function" "real_time_trading_platform_lambda_risk_calculator" {
  filename         = "risk_calculator.zip"
  function_name    = "real-time-trading-platform-lambda-risk-calculator"
  role            = aws_iam_role.real_time_trading_platform_role_lambda_risk.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30
  
  environment {
    variables = {
      DB_ENDPOINT = aws_db_instance.real_time_trading_platform_rds_trade_database.endpoint
      KINESIS_STREAM = aws_kinesis_stream.real_time_trading_platform_kinesis_market_data.name
    }
  }
  
  tags = {
    Name = "real-time-trading-platform-lambda-risk-calculator"
  }
}

# Kinesis Stream for Market Data
resource "aws_kinesis_stream" "real_time_trading_platform_kinesis_market_data" {
  name             = "real-time-trading-platform-kinesis-market-data"
  shard_count      = 2
  retention_period = 24
  
  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"
  
  tags = {
    Name = "real-time-trading-platform-kinesis-market-data"
  }
}

# S3 Bucket for Audit Logs with vulnerabilities
resource "aws_s3_bucket" "real_time_trading_platform_s3_audit_logs" {
  bucket = "real-time-trading-platform-s3-audit-logs-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "real-time-trading-platform-s3-audit-logs"
  }
}

resource "aws_s3_bucket_versioning" "real_time_trading_platform_s3_versioning_audit" {
  bucket = aws_s3_bucket.real_time_trading_platform_s3_audit_logs.id
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"  # VULNERABILITY: AWS-S3-REQUIRE_MFA_DELETE
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Application Load Balancer
resource "aws_lb" "real_time_trading_platform_alb_client_portal" {
  name               = "rt-trading-platform-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.real_time_trading_platform_sg_alb.id]
  subnets           = [aws_subnet.real_time_trading_platform_subnet_public.id, aws_subnet.real_time_trading_platform_subnet_private_app.id]
  
  tags = {
    Name = "real-time-trading-platform-alb-client-portal"
  }
}

resource "aws_security_group" "real_time_trading_platform_sg_alb" {
  name_prefix = "real-time-trading-platform-sg-alb"
  vpc_id      = aws_vpc.real_time_trading_platform_vpc_main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
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
    Name = "real-time-trading-platform-sg-alb"
  }
}

# CloudTrail with vulnerability
resource "aws_cloudtrail" "real_time_trading_platform_cloudtrail_audit" {
  name           = "real-time-trading-platform-cloudtrail-audit"
  s3_bucket_name = aws_s3_bucket.real_time_trading_platform_s3_audit_logs.bucket
  
  # VULNERABILITY: AWS-CLOUDTRAIL-ENABLE_LOG_VALIDATION - Missing log file validation
  
  tags = {
    Name = "real-time-trading-platform-cloudtrail-audit"
  }
}

# IAM Password Policy with vulnerability
resource "aws_iam_account_password_policy" "real_time_trading_platform_password_policy" {
  minimum_password_length        = 8
  require_uppercase_characters   = true
  require_numbers               = true
  require_symbols               = true
  # VULNERABILITY: AWS-IAM-REQUIRE_LOWERCASE_IN_PASSWORDS - Missing lowercase requirement
  allow_users_to_change_password = true
  max_password_age              = 90
  password_reuse_prevention     = 5
}