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
  region = var.primary_region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# VPC and Networking
resource "aws_vpc" "corporate_backup_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-vpc-main"
    Environment = var.environment
    Project     = "corporate-backup-disaster-recovery"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.corporate_backup_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-subnet-public"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.corporate_backup_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-subnet-private"
    Environment = var.environment
    Type        = "private"
  }
}

resource "aws_subnet" "data_subnet" {
  vpc_id            = aws_vpc.corporate_backup_vpc.id
  cidr_block        = var.data_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-subnet-data"
    Environment = var.environment
    Type        = "data"
  }
}

resource "aws_internet_gateway" "corporate_backup_igw" {
  vpc_id = aws_vpc.corporate_backup_vpc.id

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-igw-main"
    Environment = var.environment
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.corporate_backup_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.corporate_backup_igw.id
  }

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-rt-public"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Network ACL with excessive permissions (vulnerability)
resource "aws_network_acl" "backup_gateway_nacl" {
  vpc_id = aws_vpc.corporate_backup_vpc.id

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-nacl-gateway"
    Environment = var.environment
  }
}

resource "aws_network_acl_rule" "backup_gateway_ingress" {
  network_acl_id = aws_network_acl.backup_gateway_nacl.id
  rule_number    = 100
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# Security Groups
resource "aws_security_group" "backup_gateway_sg" {
  name        = "corporate-backup-and-disaster-recovery-system-sg-gateway"
  description = "Security group for backup gateway"
  vpc_id      = aws_vpc.corporate_backup_vpc.id

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-sg-gateway"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "corporate-backup-and-disaster-recovery-system-sg-rds"
  description = "Security group for RDS backup metadata database"
  vpc_id      = aws_vpc.corporate_backup_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-sg-rds"
    Environment = var.environment
  }
}

# Primary Backup Storage (S3) - Missing public access block configuration
resource "aws_s3_bucket" "primary_backup_storage" {
  bucket = "corporate-backup-and-disaster-recovery-system-s3-primary-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-s3-primary"
    Environment = var.environment
    Purpose     = "primary-backup-storage"
  }
}

resource "aws_s3_bucket_public_access_block" "primary_backup_pab" {
  bucket = aws_s3_bucket.primary_backup_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = false  # Vulnerability: Should be true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "primary_backup_versioning" {
  bucket = aws_s3_bucket.primary_backup_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Disaster Recovery Storage (S3) - Missing versioning
resource "aws_s3_bucket" "disaster_recovery_storage" {
  provider = aws.dr
  bucket   = "corporate-backup-and-disaster-recovery-system-s3-dr-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-s3-dr"
    Environment = var.environment
    Purpose     = "disaster-recovery-storage"
  }
}

# Vulnerability: No versioning configuration for DR bucket

resource "aws_s3_bucket_replication_configuration" "primary_to_dr" {
  role   = aws_iam_role.replication_role.arn
  bucket = aws_s3_bucket.primary_backup_storage.id

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.disaster_recovery_storage.arn
      storage_class = "STANDARD_IA"
    }
  }

  depends_on = [aws_s3_bucket_versioning.primary_backup_versioning]
}

# Random ID for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# IAM Role for S3 Replication
resource "aws_iam_role" "replication_role" {
  name = "corporate-backup-and-disaster-recovery-system-role-replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

# RDS Subnet Group
resource "aws_db_subnet_group" "backup_metadata_subnet_group" {
  name       = "corporate-backup-and-disaster-recovery-system-subnet-group-rds"
  subnet_ids = [aws_subnet.data_subnet.id, aws_subnet.private_subnet.id]

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-subnet-group-rds"
    Environment = var.environment
  }
}

# Backup Metadata Database (RDS) - Publicly accessible vulnerability
resource "aws_db_instance" "backup_metadata_db" {
  identifier = "corporate-backup-and-disaster-recovery-system-rds-metadata"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "backup_metadata"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.backup_metadata_subnet_group.name

  publicly_accessible = true  # Vulnerability: Should be false

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-rds-metadata"
    Environment = var.environment
    Purpose     = "backup-metadata-storage"
  }
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "corporate-backup-and-disaster-recovery-system-role-lambda"

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

# Backup Orchestration Lambda - Missing X-Ray tracing
resource "aws_lambda_function" "backup_orchestration" {
  filename         = "backup_orchestration.zip"
  function_name    = "corporate-backup-and-disaster-recovery-system-lambda-orchestration"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  # Vulnerability: Missing tracing_config or set to PassThrough
  tracing_config {
    mode = "PassThrough"  # Should be "Active"
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_ENDPOINT = aws_db_instance.backup_metadata_db.endpoint
      S3_BUCKET   = aws_s3_bucket.primary_backup_storage.bucket
    }
  }

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-lambda-orchestration"
    Environment = var.environment
    Purpose     = "backup-orchestration"
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "corporate-backup-and-disaster-recovery-system-sg-lambda"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.corporate_backup_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-sg-lambda"
    Environment = var.environment
  }
}

# Backup Gateway EC2 Instance
resource "aws_instance" "backup_gateway" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet.id

  vpc_security_group_ids = [aws_security_group.backup_gateway_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.backup_gateway_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    s3_bucket = aws_s3_bucket.primary_backup_storage.bucket
  }))

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-ec2-gateway"
    Environment = var.environment
    Purpose     = "backup-gateway"
  }
}

resource "aws_iam_instance_profile" "backup_gateway_profile" {
  name = "corporate-backup-and-disaster-recovery-system-profile-gateway"
  role = aws_iam_role.backup_gateway_role.name
}

resource "aws_iam_role" "backup_gateway_role" {
  name = "corporate-backup-and-disaster-recovery-system-role-gateway"

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
}

# CloudTrail for monitoring - Missing customer-managed encryption and log validation
resource "aws_cloudtrail" "backup_monitoring" {
  name           = "corporate-backup-and-disaster-recovery-system-cloudtrail-monitoring"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket

  # Vulnerability: Missing kms_key_id (customer-managed encryption)
  # Vulnerability: Missing enable_log_file_validation

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.primary_backup_storage.arn}/*"]
    }
  }

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-cloudtrail-monitoring"
    Environment = var.environment
    Purpose     = "backup-monitoring"
  }
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "corporate-backup-and-disaster-recovery-system-s3-cloudtrail-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-s3-cloudtrail"
    Environment = var.environment
    Purpose     = "cloudtrail-logs"
  }
}

# IAM Password Policy with weak password reuse prevention
resource "aws_iam_account_password_policy" "backup_system_policy" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers               = true
  require_uppercase_characters   = true
  require_symbols               = true
  allow_users_to_change_password = true
  password_reuse_prevention     = 1  # Vulnerability: Should be 5 or higher
  max_password_age              = 90
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "backup_logs" {
  name              = "/aws/lambda/corporate-backup-and-disaster-recovery-system"
  retention_in_days = 14

  tags = {
    Name        = "corporate-backup-and-disaster-recovery-system-logs-backup"
    Environment = var.environment
    Purpose     = "backup-monitoring"
  }
}