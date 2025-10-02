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

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# VPC and Networking
resource "aws_vpc" "secure_network" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "digital-asset-trading-platform-vpc-main"
    Environment = var.environment
    Project     = "digital-asset-trading-platform"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.secure_network.id

  tags = {
    Name        = "digital-asset-trading-platform-igw-main"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.secure_network.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "digital-asset-trading-platform-subnet-public-${count.index + 1}"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.secure_network.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "digital-asset-trading-platform-subnet-private-${count.index + 1}"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_subnet" "data" {
  count             = 2
  vpc_id            = aws_vpc.secure_network.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "digital-asset-trading-platform-subnet-data-${count.index + 1}"
    Environment = var.environment
    Type        = "data"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.secure_network.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "digital-asset-trading-platform-rt-public"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "ecs_cluster" {
  name        = "digital-asset-trading-platform-sg-ecs"
  description = "Security group for ECS trading engine cluster"
  vpc_id      = aws_vpc.secure_network.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

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
    Name        = "digital-asset-trading-platform-sg-ecs"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds" {
  name        = "digital-asset-trading-platform-sg-rds"
  description = "Security group for RDS trade database"
  vpc_id      = aws_vpc.secure_network.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_cluster.id]
  }

  tags = {
    Name        = "digital-asset-trading-platform-sg-rds"
    Environment = var.environment
  }
}

resource "aws_security_group" "redis" {
  name        = "digital-asset-trading-platform-sg-redis"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.secure_network.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_cluster.id]
  }

  tags = {
    Name        = "digital-asset-trading-platform-sg-redis"
    Environment = var.environment
  }
}

# KMS Key with vulnerability - no key rotation
resource "aws_kms_key" "trading_platform" {
  description             = "KMS key for digital asset trading platform encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = false

  tags = {
    Name        = "digital-asset-trading-platform-kms-main"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "trading_platform" {
  name          = "alias/digital-asset-trading-platform-key"
  target_key_id = aws_kms_key.trading_platform.key_id
}

# RDS Database with vulnerability - no encryption
resource "aws_db_subnet_group" "trade_database" {
  name       = "digital-asset-trading-platform-db-subnet-group"
  subnet_ids = aws_subnet.data[*].id

  tags = {
    Name        = "digital-asset-trading-platform-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_rds_cluster" "trade_database" {
  cluster_identifier      = "digital-asset-trading-platform-rds-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "13.7"
  database_name           = "trading_db"
  master_username         = var.db_username
  master_password         = var.db_password
  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"
  db_subnet_group_name    = aws_db_subnet_group.trade_database.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  skip_final_snapshot     = true

  tags = {
    Name        = "digital-asset-trading-platform-rds-cluster"
    Environment = var.environment
  }
}

resource "aws_rds_cluster_instance" "trade_database_instances" {
  count              = 2
  identifier         = "digital-asset-trading-platform-rds-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.trade_database.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.trade_database.engine
  engine_version     = aws_rds_cluster.trade_database.engine_version

  tags = {
    Name        = "digital-asset-trading-platform-rds-instance-${count.index}"
    Environment = var.environment
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_subnet_group" "market_data_cache" {
  name       = "digital-asset-trading-platform-cache-subnet-group"
  subnet_ids = aws_subnet.data[*].id
}

resource "aws_elasticache_replication_group" "market_data_cache" {
  replication_group_id       = "digital-asset-trading-platform-redis-cluster"
  description                = "Redis cluster for market data caching"
  node_type                  = var.redis_node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  subnet_group_name          = aws_elasticache_subnet_group.market_data_cache.name
  security_group_ids         = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = {
    Name        = "digital-asset-trading-platform-redis-cluster"
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "trading_engine_cluster" {
  name = "digital-asset-trading-platform-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "digital-asset-trading-platform-ecs-cluster"
    Environment = var.environment
  }
}

# IAM Role for ECS Tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "digital-asset-trading-platform-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "digital-asset-trading-platform-ecs-task-execution-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition with vulnerability - plaintext secrets
resource "aws_ecs_task_definition" "trading_engine" {
  family                   = "digital-asset-trading-platform-trading-engine"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "trading-engine"
      image = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "DATABASE_PASSWORD"
          value = "super-secret-password-123!"
        },
        {
          name  = "API_KEY"
          value = "ak-prod-12345-trading-api-key"
        },
        {
          name  = "ENCRYPTION_KEY"
          value = "enc-key-aes256-trading-platform-2023"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/digital-asset-trading-platform"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "digital-asset-trading-platform-trading-engine-task"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/digital-asset-trading-platform"
  retention_in_days = 30

  tags = {
    Name        = "digital-asset-trading-platform-ecs-logs"
    Environment = var.environment
  }
}

# S3 Bucket for compliance storage with vulnerability - no read logging
resource "aws_s3_bucket" "compliance_storage" {
  bucket = "digital-asset-trading-platform-compliance-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "digital-asset-trading-platform-s3-compliance"
    Environment = var.environment
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "compliance_storage" {
  bucket = aws_s3_bucket.compliance_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "compliance_storage" {
  bucket = aws_s3_bucket.compliance_storage.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.trading_platform.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "compliance_storage" {
  bucket = aws_s3_bucket.compliance_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# API Gateway with vulnerability - no X-Ray tracing
resource "aws_api_gateway_rest_api" "trading_api" {
  name        = "digital-asset-trading-platform-api"
  description = "API Gateway for digital asset trading platform"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "digital-asset-trading-platform-api-gateway"
    Environment = var.environment
  }
}

resource "aws_api_gateway_deployment" "trading_api" {
  depends_on = [
    aws_api_gateway_method.trading_api_method,
    aws_api_gateway_integration.trading_api_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.trading_api.id
  stage_name  = "dev"
}

resource "aws_api_gateway_stage" "trading_api" {
  deployment_id        = aws_api_gateway_deployment.trading_api.id
  rest_api_id          = aws_api_gateway_rest_api.trading_api.id
  stage_name           = var.environment
  xray_tracing_enabled = false

  tags = {
    Name        = "digital-asset-trading-platform-api-stage"
    Environment = var.environment
  }
}

resource "aws_api_gateway_resource" "trading_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.trading_api.id
  parent_id   = aws_api_gateway_rest_api.trading_api.root_resource_id
  path_part   = "trades"
}

resource "aws_api_gateway_method" "trading_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.trading_api.id
  resource_id   = aws_api_gateway_resource.trading_api_resource.id
  http_method   = "GET"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "trading_api_integration" {
  rest_api_id = aws_api_gateway_rest_api.trading_api.id
  resource_id = aws_api_gateway_resource.trading_api_resource.id
  http_method = aws_api_gateway_method.trading_api_method.http_method
  type        = "MOCK"
}

# Cognito User Pool
resource "aws_cognito_user_pool" "user_auth_service" {
  name = "digital-asset-trading-platform-user-pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_uppercase = true
  }

  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  tags = {
    Name        = "digital-asset-trading-platform-cognito-user-pool"
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "user_auth_client" {
  name         = "digital-asset-trading-platform-client"
  user_pool_id = aws_cognito_user_pool.user_auth_service.id

  generate_secret = true

  explicit_auth_flows = [
    "ADMIN_NO_SRP_AUTH",
    "USER_PASSWORD_AUTH"
  ]
}

# IAM Password Policy with vulnerability - no symbols required
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 12
  require_lowercase_characters   = true
  require_numbers               = true
  require_uppercase_characters   = true
  allow_users_to_change_password = true
  max_password_age              = 90
  password_reuse_prevention     = 5
}