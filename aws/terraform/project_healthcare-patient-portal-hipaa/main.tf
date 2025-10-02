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
resource "aws_vpc" "hipaa_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "hipaa-compliant-patient-portal-vpc-main"
    Environment = var.environment
    Project     = "healthcare-patient-portal-hipaa"
  }
}

resource "aws_internet_gateway" "hipaa_igw" {
  vpc_id = aws_vpc.hipaa_vpc.id

  tags = {
    Name        = "hipaa-compliant-patient-portal-igw-main"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.hipaa_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "hipaa-compliant-patient-portal-subnet-public-1"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.hipaa_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "hipaa-compliant-patient-portal-subnet-public-2"
    Environment = var.environment
    Type        = "public"
  }
}

resource "aws_subnet" "private_app_subnet_1" {
  vpc_id                  = aws_vpc.hipaa_vpc.id
  cidr_block              = var.private_app_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "hipaa-compliant-patient-portal-subnet-private-app-1"
    Environment = var.environment
    Type        = "private-app"
  }
}

resource "aws_subnet" "private_app_subnet_2" {
  vpc_id                  = aws_vpc.hipaa_vpc.id
  cidr_block              = var.private_app_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "hipaa-compliant-patient-portal-subnet-private-app-2"
    Environment = var.environment
    Type        = "private-app"
  }
}

resource "aws_subnet" "private_data_subnet_1" {
  vpc_id            = aws_vpc.hipaa_vpc.id
  cidr_block        = var.private_data_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "hipaa-compliant-patient-portal-subnet-private-data-1"
    Environment = var.environment
    Type        = "private-data"
  }
}

resource "aws_subnet" "private_data_subnet_2" {
  vpc_id            = aws_vpc.hipaa_vpc.id
  cidr_block        = var.private_data_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "hipaa-compliant-patient-portal-subnet-private-data-2"
    Environment = var.environment
    Type        = "private-data"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.hipaa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hipaa_igw.id
  }

  tags = {
    Name        = "hipaa-compliant-patient-portal-rt-public"
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
  name   = "hipaa-compliant-patient-portal-sg-alb"
  vpc_id = aws_vpc.hipaa_vpc.id

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
    Name        = "hipaa-compliant-patient-portal-sg-alb"
    Environment = var.environment
  }
}

resource "aws_security_group" "web_sg" {
  name   = "hipaa-compliant-patient-portal-sg-web"
  vpc_id = aws_vpc.hipaa_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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
    Name        = "hipaa-compliant-patient-portal-sg-web"
    Environment = var.environment
  }
}

resource "aws_security_group" "db_sg" {
  name   = "hipaa-compliant-patient-portal-sg-db"
  vpc_id = aws_vpc.hipaa_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  tags = {
    Name        = "hipaa-compliant-patient-portal-sg-db"
    Environment = var.environment
  }
}

# Application Load Balancer
resource "aws_lb" "hipaa_alb" {
  name               = "hipaa-patient-portal-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name        = "hipaa-compliant-patient-portal-alb-main"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "hipaa-patient-portal-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.hipaa_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "hipaa-compliant-patient-portal-tg-web"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.hipaa_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# EC2 Instances for Web Application Tier
resource "aws_instance" "web_server_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_app_subnet_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "hipaa-compliant-patient-portal-ec2-web-1"
    Environment = var.environment
    Role        = "web-server"
  }
}

resource "aws_instance" "web_server_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_app_subnet_2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "hipaa-compliant-patient-portal-ec2-web-2"
    Environment = var.environment
    Role        = "web-server"
  }
}

resource "aws_lb_target_group_attachment" "web_tg_attachment_1" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_tg_attachment_2" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}

# RDS Database Subnet Group
resource "aws_db_subnet_group" "hipaa_db_subnet_group" {
  name       = "hipaa-patient-portal-db-subnet-group"
  subnet_ids = [aws_subnet.private_data_subnet_1.id, aws_subnet.private_data_subnet_2.id]

  tags = {
    Name        = "hipaa-compliant-patient-portal-db-subnet-group"
    Environment = var.environment
  }
}

# RDS MySQL Database - VULNERABLE: Missing encryption and publicly accessible
resource "aws_db_instance" "hipaa_database" {
  identifier             = "hipaa-patient-portal-db"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.hipaa_db_subnet_group.name
  publicly_accessible    = true
  skip_final_snapshot    = true

  tags = {
    Name        = "hipaa-compliant-patient-portal-rds-mysql"
    Environment = var.environment
  }
}

# S3 Bucket for File Storage - VULNERABLE: Missing public access block
resource "aws_s3_bucket" "file_storage" {
  bucket = "hipaa-patient-portal-files-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "hipaa-compliant-patient-portal-s3-files"
    Environment = var.environment
    Purpose     = "medical-documents"
  }
}

resource "aws_s3_bucket_versioning" "file_storage_versioning" {
  bucket = aws_s3_bucket.file_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "file_storage_encryption" {
  bucket = aws_s3_bucket.file_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket for Backup Storage - VULNERABLE: Public ACLs not ignored
resource "aws_s3_bucket" "backup_storage" {
  bucket = "hipaa-patient-portal-backups-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "hipaa-compliant-patient-portal-s3-backups"
    Environment = var.environment
    Purpose     = "database-backups"
  }
}

resource "aws_s3_bucket_public_access_block" "backup_storage_pab" {
  bucket = aws_s3_bucket.backup_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "backup_storage_versioning" {
  bucket = aws_s3_bucket.backup_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CloudWatch Log Group for Audit Logging
resource "aws_cloudwatch_log_group" "hipaa_audit_logs" {
  name              = "/aws/hipaa-patient-portal/audit"
  retention_in_days = 365

  tags = {
    Name        = "hipaa-compliant-patient-portal-logs-audit"
    Environment = var.environment
    Purpose     = "hipaa-audit-trail"
  }
}

# CloudTrail for audit logging - VULNERABLE: S3 bucket without access logging
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "hipaa-patient-portal-cloudtrail-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "hipaa-compliant-patient-portal-s3-cloudtrail"
    Environment = var.environment
  }
}

resource "aws_cloudtrail" "hipaa_audit_trail" {
  name           = "hipaa-patient-portal-audit-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []
  }

  tags = {
    Name        = "hipaa-compliant-patient-portal-cloudtrail-main"
    Environment = var.environment
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}