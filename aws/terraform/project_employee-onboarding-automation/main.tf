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

# KMS Key for encryption (vulnerable - no auto rotation)
resource "aws_kms_key" "onboarding_key" {
  description         = "KMS key for employee onboarding platform"
  enable_key_rotation = false
  
  tags = {
    Name        = "automated-employee-onboarding-platform-kms-key"
    Environment = var.environment
    Project     = "employee-onboarding-automation"
  }
}

resource "aws_kms_alias" "onboarding_key_alias" {
  name          = "alias/employee-onboarding-key"
  target_key_id = aws_kms_key.onboarding_key.key_id
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "automated-employee-onboarding-platform-vpc-main"
    Environment = var.environment
    Project     = "employee-onboarding-automation"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "automated-employee-onboarding-platform-igw-main"
    Environment = var.environment
    Project     = "employee-onboarding-automation"
  }
}

# Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "automated-employee-onboarding-platform-subnet-public-1"
    Environment = var.environment
    Type        = "Public"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "automated-employee-onboarding-platform-subnet-public-2"
    Environment = var.environment
    Type        = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "automated-employee-onboarding-platform-subnet-private-1"
    Environment = var.environment
    Type        = "Private"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "automated-employee-onboarding-platform-subnet-private-2"
    Environment = var.environment
    Type        = "Private"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "automated-employee-onboarding-platform-rt-public"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# S3 Bucket for Document Storage (vulnerable - no public access block, no CloudTrail)
resource "aws_s3_bucket" "document_storage" {
  bucket = "automated-employee-onboarding-platform-documents-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "automated-employee-onboarding-platform-s3-documents"
    Environment = var.environment
    Project     = "employee-onboarding-automation"
  }
}

resource "aws_s3_bucket_versioning" "document_storage" {
  bucket = aws_s3_bucket.document_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "document_storage" {
  bucket = aws_s3_bucket.document_storage.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.onboarding_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# SQS Queue for Task Processing (vulnerable - using AWS managed key)
resource "aws_sqs_queue" "task_queue" {
  name                      = "automated-employee-onboarding-platform-queue-tasks"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10
  kms_master_key_id        = "alias/aws/sqs"

  tags = {
    Name        = "automated-employee-onboarding-platform-sqs-tasks"
    Environment = var.environment
    Project     = "employee-onboarding-automation"
  }
}

resource "aws_sqs_queue" "task_queue_dlq" {
  name = "automated-employee-onboarding-platform-queue-tasks-dlq"

  tags = {
    Name        = "automated-employee-onboarding-platform-sqs-tasks-dlq"
    Environment = var.environment
    Project     = "employee-onboarding-automation"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "employee_db" {
  name       = "automated-employee-onboarding-platform-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name        = "automated-employee-onboarding-platform-db-subnet-group"
    Environment = var.environment
  }
}

# RDS Instance (vulnerable - performance insights without customer key)
resource "aws_db_instance" "employee_database" {
  identifier             = "automated-employee-onboarding-platform-db-employees"
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "13.13"
  instance_class         = var.db_instance_class
  db_name                = "employee_onboarding"
  username               = var.db_username
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.employee_db.name
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  storage_encrypted      = true
  kms_key_id            = aws_kms_key.onboarding_key.arn
  performance_insights_enabled = true
  performance_insights_kms_key_id = ""
  skip_final_snapshot   = true

  tags = {
    Name        = "automated-employee-onboarding-platform-rds-employees"
    Environment = var.environment
    Project     = "employee-onboarding-automation"
  }
}

# Security Groups (vulnerable - missing descriptions)
resource "aws_security_group" "alb" {
  name        = "automated-employee-onboarding-platform-sg-alb"
  description = ""
  vpc_id      = aws_vpc.main.id

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
    Name        = "automated-employee-onboarding-platform-sg-alb"
    Environment = var.environment
  }
}

resource "aws_security_group" "web_app" {
  name        = "automated-employee-onboarding-platform-sg-web"
  description = ""
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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
    Name        = "automated-employee-onboarding-platform-sg-web"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds" {
  name        = "automated-employee-onboarding-platform-sg-rds"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_app.id, aws_security_group.lambda.id]
  }

  tags = {
    Name        = "automated-employee-onboarding-platform-sg-rds"
    Environment = var.environment
  }
}

resource "aws_security_group" "lambda" {
  name        = "automated-employee-onboarding-platform-sg-lambda"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "automated-employee-onboarding-platform-sg-lambda"
    Environment = var.environment
  }
}

# Application Load Balancer (vulnerable - not dropping invalid headers)
resource "aws_lb" "main" {
  name               = "automated-employee-onboarding-platform-alb-main"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  drop_invalid_header_fields = false

  tags = {
    Name        = "automated-employee-onboarding-platform-alb-main"
    Environment = var.environment
    Project     = "employee-onboarding-automation"
  }
}

resource "aws_lb_target_group" "web_app" {
  name     = "automated-employee-onboarding-platform-tg-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

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
    Name        = "automated-employee-onboarding-platform-tg-web"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "web_app" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app.arn
  }
}

# Launch Template (vulnerable - sensitive info in user data)
resource "aws_launch_template" "web_app" {
  name_prefix   = "automated-employee-onboarding-platform-lt-web-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.web_app.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              export DATABASE_PASSWORD="${var.db_password}"
              export API_KEY="sk-1234567890abcdef"
              apt-get update
              apt-get install -y nginx nodejs npm
              systemctl start nginx
              systemctl enable nginx
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "automated-employee-onboarding-platform-ec2-web"
      Environment = var.environment
      Project     = "employee-onboarding-automation"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_app" {
  name                = "automated-employee-onboarding-platform-asg-web"
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  target_group_arns   = [aws_lb_target_group.web_app.arn]
  health_check_type   = "ELB"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.web_app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "automated-employee-onboarding-platform-asg-web"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "automated-employee-onboarding-platform-role-lambda"

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
    Name        = "automated-employee-onboarding-platform-role-lambda"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Lambda Function
resource "aws_lambda_function" "onboarding_api" {
  filename         = "lambda_function.zip"
  function_name    = "automated-employee-onboarding-platform-lambda-api"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 30

  vpc_config {
    subnet_ids         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST     = aws_db_instance.employee_database.endpoint
      DB_NAME     = aws_db_instance.employee_database.db_name
      SQS_QUEUE   = aws_sqs_queue.task_queue.url
      S3_BUCKET   = aws_s3_bucket.document_storage.bucket
    }
  }

  tags = {
    Name        = "automated-employee-onboarding-platform-lambda-api"
    Environment = var.environment
    Project     = "employee-onboarding-automation"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source {
    content = <<EOF
import json
import boto3

def handler(event, context):
    return {
        'statusCode': 200,
        'body': json.dumps('Employee Onboarding API')
    }
EOF
    filename = "index.py"
  }
}