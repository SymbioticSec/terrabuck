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
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 Bucket for video storage
resource "aws_s3_bucket" "corporate_training_video_streaming_platform_storage_primary" {
  bucket = "${var.project_name}-video-storage-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Corporate Training Video Storage"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "video_storage_versioning" {
  bucket = aws_s3_bucket.corporate_training_video_streaming_platform_storage_primary.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "video_storage_encryption" {
  bucket = aws_s3_bucket.corporate_training_video_streaming_platform_storage_primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "video_storage_logging" {
  bucket = aws_s3_bucket.corporate_training_video_streaming_platform_storage_primary.id

  target_bucket = aws_s3_bucket.corporate_training_video_streaming_platform_storage_logs.id
  target_prefix = "access-logs/"
}

# S3 Bucket for access logs
resource "aws_s3_bucket" "corporate_training_video_streaming_platform_storage_logs" {
  bucket = "${var.project_name}-access-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Corporate Training Access Logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "corporate_training_video_streaming_platform_cdn_oai" {
  comment = "OAI for corporate training video streaming platform"
}

# CloudFront Distribution - VULNERABLE: Uses TLS 1.0
resource "aws_cloudfront_distribution" "corporate_training_video_streaming_platform_cdn_distribution" {
  origin {
    domain_name = aws_s3_bucket.corporate_training_video_streaming_platform_storage_primary.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.corporate_training_video_streaming_platform_storage_primary.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.corporate_training_video_streaming_platform_cdn_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.corporate_training_video_streaming_platform_storage_primary.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # VULNERABILITY: Using insecure TLS 1.0
  viewer_certificate {
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.0"
    ssl_support_method             = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "Corporate Training CDN"
    Environment = var.environment
    Project     = var.project_name
  }
}

# DynamoDB Table for video metadata and user progress
resource "aws_dynamodb_table" "corporate_training_video_streaming_platform_database_metadata" {
  name           = "${var.project_name}-video-metadata"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "video_id"
  range_key      = "user_id"

  attribute {
    name = "video_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "Corporate Training Video Metadata"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Cognito User Pool
resource "aws_cognito_user_pool" "corporate_training_video_streaming_platform_user_pool" {
  name = "${var.project_name}-user-pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_uppercase = true
    # VULNERABILITY: Not requiring symbols in passwords
  }

  mfa_configuration = "OPTIONAL"

  tags = {
    Name        = "Corporate Training User Pool"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "corporate_training_video_streaming_platform_user_pool_client" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.corporate_training_video_streaming_platform_user_pool.id

  generate_secret = true

  explicit_auth_flows = [
    "ADMIN_NO_SRP_AUTH",
    "USER_PASSWORD_AUTH"
  ]
}

# IAM Role for Lambda functions
resource "aws_iam_role" "corporate_training_video_streaming_platform_lambda_role" {
  name = "${var.project_name}-lambda-role"

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
    Name        = "Corporate Training Lambda Role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for Lambda functions
resource "aws_iam_role_policy" "corporate_training_video_streaming_platform_lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.corporate_training_video_streaming_platform_lambda_role.id

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
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.corporate_training_video_streaming_platform_database_metadata.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.corporate_training_video_streaming_platform_storage_primary.arn}/*"
      }
    ]
  })
}

# CloudWatch Log Group - VULNERABLE: No customer-managed KMS key
resource "aws_cloudwatch_log_group" "corporate_training_video_streaming_platform_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-processing"
  retention_in_days = 14

  tags = {
    Name        = "Corporate Training Lambda Logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda function for video processing
resource "aws_lambda_function" "corporate_training_video_streaming_platform_processing_video" {
  filename         = "video_processing.zip"
  function_name    = "${var.project_name}-video-processing"
  role            = aws_iam_role.corporate_training_video_streaming_platform_lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.corporate_training_video_streaming_platform_database_metadata.name
      S3_BUCKET      = aws_s3_bucket.corporate_training_video_streaming_platform_storage_primary.id
    }
  }

  depends_on = [
    aws_iam_role_policy.corporate_training_video_streaming_platform_lambda_policy,
    aws_cloudwatch_log_group.corporate_training_video_streaming_platform_lambda_logs,
  ]

  tags = {
    Name        = "Corporate Training Video Processing"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "corporate_training_video_streaming_platform_api_gateway" {
  name        = "${var.project_name}-api"
  description = "API for corporate training video streaming platform"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "Corporate Training API"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway Domain Name - VULNERABLE: Uses TLS 1.0
resource "aws_api_gateway_domain_name" "corporate_training_video_streaming_platform_api_domain" {
  domain_name     = "${var.project_name}.${var.domain_name}"
  certificate_arn = aws_acm_certificate.corporate_training_video_streaming_platform_cert.arn
  security_policy = "TLS_1_0"

  tags = {
    Name        = "Corporate Training API Domain"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ACM Certificate
resource "aws_acm_certificate" "corporate_training_video_streaming_platform_cert" {
  domain_name       = "${var.project_name}.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Corporate Training Certificate"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway Method Settings - VULNERABLE: Cache enabled but not encrypted
resource "aws_api_gateway_method_settings" "corporate_training_video_streaming_platform_api_settings" {
  rest_api_id = aws_api_gateway_rest_api.corporate_training_video_streaming_platform_api_gateway.id
  stage_name  = aws_api_gateway_stage.corporate_training_video_streaming_platform_api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    caching_enabled    = true
    cache_data_encrypted = false  # VULNERABILITY: Cache not encrypted
    cache_ttl_in_seconds = 300
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "corporate_training_video_streaming_platform_api_stage" {
  deployment_id = aws_api_gateway_deployment.corporate_training_video_streaming_platform_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.corporate_training_video_streaming_platform_api_gateway.id
  stage_name    = var.environment

  tags = {
    Name        = "Corporate Training API Stage"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "corporate_training_video_streaming_platform_api_deployment" {
  depends_on = [
    aws_api_gateway_method.corporate_training_video_streaming_platform_api_method,
  ]

  rest_api_id = aws_api_gateway_rest_api.corporate_training_video_streaming_platform_api_gateway.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.corporate_training_video_streaming_platform_api_gateway.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Resource
resource "aws_api_gateway_resource" "corporate_training_video_streaming_platform_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.corporate_training_video_streaming_platform_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.corporate_training_video_streaming_platform_api_gateway.root_resource_id
  path_part   = "videos"
}

# API Gateway Method
resource "aws_api_gateway_method" "corporate_training_video_streaming_platform_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.corporate_training_video_streaming_platform_api_gateway.id
  resource_id   = aws_api_gateway_resource.corporate_training_video_streaming_platform_api_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.corporate_training_video_streaming_platform_api_authorizer.id
}

# API Gateway Authorizer
resource "aws_api_gateway_authorizer" "corporate_training_video_streaming_platform_api_authorizer" {
  name                   = "${var.project_name}-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.corporate_training_video_streaming_platform_api_gateway.id
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = [aws_cognito_user_pool.corporate_training_video_streaming_platform_user_pool.arn]
}

# Secrets Manager Secret - VULNERABLE: No customer-managed KMS key
resource "aws_secretsmanager_secret" "corporate_training_video_streaming_platform_secrets" {
  name = "${var.project_name}-database-credentials"
  description = "Database credentials for corporate training platform"

  tags = {
    Name        = "Corporate Training Secrets"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudTrail - VULNERABLE: Single region only
resource "aws_cloudtrail" "corporate_training_video_streaming_platform_audit_trail" {
  name           = "${var.project_name}-audit-trail"
  s3_bucket_name = aws_s3_bucket.corporate_training_video_streaming_platform_storage_logs.id

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.corporate_training_video_streaming_platform_storage_primary.arn}/*"]
    }
  }

  tags = {
    Name        = "Corporate Training Audit Trail"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Account Password Policy - VULNERABLE: No symbols required
resource "aws_iam_account_password_policy" "corporate_training_video_streaming_platform_password_policy" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers               = true
  require_uppercase_characters  = true
  allow_users_to_change_password = true
  max_password_age              = 90
  password_reuse_prevention     = 5
}