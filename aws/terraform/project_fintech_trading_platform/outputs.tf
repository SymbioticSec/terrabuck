output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.real_time_trading_platform_vpc_main.id
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.real_time_trading_platform_rds_trade_database.endpoint
  sensitive   = true
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis stream for market data"
  value       = aws_kinesis_stream.real_time_trading_platform_kinesis_market_data.name
}

output "trading_engine_instance_ids" {
  description = "Instance IDs of trading engine servers"
  value       = aws_instance.real_time_trading_platform_ec2_trading_engine[*].id
}

output "load_balancer_dns" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.real_time_trading_platform_alb_client_portal.dns_name
}

output "audit_logs_bucket" {
  description = "S3 bucket name for audit logs"
  value       = aws_s3_bucket.real_time_trading_platform_s3_audit_logs.bucket
}

output "lambda_function_name" {
  description = "Name of the risk analytics Lambda function"
  value       = aws_lambda_function.real_time_trading_platform_lambda_risk_calculator.function_name
}

output "kms_key_id" {
  description = "KMS key ID for database encryption"
  value       = aws_kms_key.real_time_trading_platform_kms_database.key_id
}