output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.secure_network.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "data_subnet_ids" {
  description = "IDs of the data subnets"
  value       = aws_subnet.data[*].id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.trading_engine_cluster.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.trading_engine_cluster.arn
}

output "rds_cluster_endpoint" {
  description = "RDS cluster endpoint"
  value       = aws_rds_cluster.trade_database.endpoint
  sensitive   = true
}

output "rds_cluster_reader_endpoint" {
  description = "RDS cluster reader endpoint"
  value       = aws_rds_cluster.trade_database.reader_endpoint
  sensitive   = true
}

output "redis_cluster_endpoint" {
  description = "Redis cluster configuration endpoint"
  value       = aws_elasticache_replication_group.market_data_cache.configuration_endpoint_address
  sensitive   = true
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = "https://${aws_api_gateway_rest_api.trading_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
}

output "s3_compliance_bucket_name" {
  description = "Name of the S3 compliance bucket"
  value       = aws_s3_bucket.compliance_storage.bucket
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.user_auth_service.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.user_auth_client.id
}

output "kms_key_id" {
  description = "KMS Key ID"
  value       = aws_kms_key.trading_platform.key_id
}

output "kms_key_arn" {
  description = "KMS Key ARN"
  value       = aws_kms_key.trading_platform.arn
}