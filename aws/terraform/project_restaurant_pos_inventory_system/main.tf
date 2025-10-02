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
    values = ["ubuntu/images/hvm-ssd/ubuntu-20.04-lts-amd64-server-*"]
  }
}

# VPC and Networking
resource "aws_vpc" "restaurant_pos_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-vpc-main"
    Environment = var.environment
    Project     = "restaurant-pos-inventory-system"
  }
}

resource "aws_internet_gateway" "restaurant_pos_igw" {
  vpc_id = aws_vpc.restaurant_pos_vpc.id

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-igw-main"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.restaurant_pos_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-subnet-public-1"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.restaurant_pos_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-subnet-public-2"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.restaurant_pos_vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-subnet-private-1"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.restaurant_pos_vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-subnet-private-2"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_subnet" "data_subnet_1" {
  vpc_id            = aws_vpc.restaurant_pos_vpc.id
  cidr_block        = var.data_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-subnet-data-1"
    Environment = var.environment
    Type        = "data"
  }
}

resource "aws_subnet" "data_subnet_2" {
  vpc_id            = aws_vpc.restaurant_pos_vpc.id
  cidr_block        = var.data_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-subnet-data-2"
    Environment = var.environment
    Type        = "data"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.restaurant_pos_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.restaurant_pos_igw.id
  }

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-rt-public"
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
resource "aws_security_group" "alb_sg" {
  name        = "restaurant-pos-alb-sg"
  description = ""
  vpc_id      = aws_vpc.restaurant_pos_vpc.id

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
    Name        = "restaurant-pos-and-inventory-management-system-sg-alb"
    Environment = var.environment
  }
}

resource "aws_security_group" "pos_app_sg" {
  name        = "restaurant-pos-app-sg"
  description = ""
  vpc_id      = aws_vpc.restaurant_pos_vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-sg-app"
    Environment = var.environment
  }
}

# IAM Role for POS Application
resource "aws_iam_role" "pos_app_role" {
  name = "restaurant-pos-app-role"

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
    Name        = "restaurant-pos-and-inventory-management-system-role-app"
    Environment = var.environment
  }
}

resource "aws_iam_instance_profile" "pos_app_profile" {
  name = "restaurant-pos-app-profile"
  role = aws_iam_role.pos_app_role.name
}

# Launch Configuration for POS Application Servers
resource "aws_launch_configuration" "pos_app_lc" {
  name_prefix          = "restaurant-pos-app-"
  image_id             = data.aws_ami.ubuntu.id
  instance_type        = var.pos_instance_type
  iam_instance_profile = aws_iam_instance_profile.pos_app_profile.name
  security_groups      = [aws_security_group.pos_app_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for POS Application Servers
resource "aws_autoscaling_group" "pos_app_asg" {
  name                 = "restaurant-pos-and-inventory-management-system-asg-pos"
  launch_configuration = aws_launch_configuration.pos_app_lc.name
  min_size             = 2
  max_size             = 6
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  target_group_arns    = [aws_lb_target_group.pos_app_tg.arn]

  tag {
    key                 = "Name"
    value               = "restaurant-pos-and-inventory-management-system-instance-pos"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_lb" "pos_alb" {
  name               = "restaurant-pos-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-lb-main"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "pos_app_tg" {
  name     = "restaurant-pos-app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.restaurant_pos_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-tg-app"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "pos_app_listener" {
  load_balancer_arn = aws_lb.pos_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pos_app_tg.arn
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "inventory_db_subnet_group" {
  name       = "restaurant-pos-inventory-db-subnet-group"
  subnet_ids = [aws_subnet.data_subnet_1.id, aws_subnet.data_subnet_2.id]

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-subnet-group-db"
    Environment = var.environment
  }
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "restaurant-pos-rds-sg"
  description = "Security group for RDS inventory database"
  vpc_id      = aws_vpc.restaurant_pos_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.pos_app_sg.id]
  }

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-sg-rds"
    Environment = var.environment
  }
}

# RDS Instance for Inventory Database
resource "aws_db_instance" "inventory_database" {
  identifier     = "restaurant-pos-inventory-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "inventory"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.inventory_db_subnet_group.name

  performance_insights_enabled = true
  performance_insights_kms_key_id = ""

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-rds-inventory"
    Environment = var.environment
  }
}

# S3 Bucket for Transaction Storage
resource "aws_s3_bucket" "transaction_storage" {
  bucket = "restaurant-pos-transaction-storage-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-s3-transactions"
    Environment = var.environment
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket_versioning" "transaction_storage_versioning" {
  bucket = aws_s3_bucket.transaction_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name       = "restaurant-pos-cache-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-subnet-group-cache"
    Environment = var.environment
  }
}

# ElastiCache Security Group
resource "aws_security_group" "cache_sg" {
  name        = "restaurant-pos-cache-sg"
  description = "Security group for ElastiCache Redis cluster"
  vpc_id      = aws_vpc.restaurant_pos_vpc.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.pos_app_sg.id]
  }

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-sg-cache"
    Environment = var.environment
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "cache_layer" {
  replication_group_id       = "restaurant-pos-cache"
  description                = "Redis cache for POS menu and inventory data"
  
  node_type                  = var.cache_node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"
  
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  subnet_group_name = aws_elasticache_subnet_group.cache_subnet_group.name
  security_group_ids = [aws_security_group.cache_sg.id]

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-cache-main"
    Environment = var.environment
  }
}

# IAM Role for Lambda Analytics Processor
resource "aws_iam_role" "analytics_lambda_role" {
  name = "restaurant-pos-analytics-lambda-role"

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
    Name        = "restaurant-pos-and-inventory-management-system-role-lambda"
    Environment = var.environment
  }
}

# Lambda Function for Analytics Processor
resource "aws_lambda_function" "analytics_processor" {
  filename         = "analytics_processor.zip"
  function_name    = "restaurant-pos-analytics-processor"
  role            = aws_iam_role.analytics_lambda_role.arn
  handler         = "index.handler"
  source_code_hash = filebase64sha256("analytics_processor.zip")
  runtime         = "python3.9"
  timeout         = 300

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_group_ids = [aws_security_group.pos_app_sg.id]
  }

  environment {
    variables = {
      DB_HOST = aws_db_instance.inventory_database.endpoint
      S3_BUCKET = aws_s3_bucket.transaction_storage.bucket
    }
  }

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-lambda-analytics"
    Environment = var.environment
  }
}

# CloudTrail for audit logging
resource "aws_cloudtrail" "pos_audit_trail" {
  name           = "restaurant-pos-audit-trail"
  s3_bucket_name = aws_s3_bucket.transaction_storage.bucket

  tags = {
    Name        = "restaurant-pos-and-inventory-management-system-cloudtrail-audit"
    Environment = var.environment
  }
}

# IAM Password Policy
resource "aws_iam_account_password_policy" "pos_password_policy" {
  minimum_password_length        = 12
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers               = true
  password_reuse_prevention     = 5
  max_password_age              = 90
}