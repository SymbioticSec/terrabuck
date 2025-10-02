output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.fleet_management_vpc.id
}

output "api_gateway_url" {
  description = "URL of the API Gateway for GPS data ingestion"
  value       = "https://${aws_api_gateway_rest_api.gps_data_ingestion.id}.execute-api.${var.aws_region}.amazonaws.com"
}

output "dashboard_public_ip" {
  description = "Public IP address of the fleet dashboard"
  value       = aws_instance.fleet_dashboard.public_ip
}

output "database_endpoint" {
  description = "RDS PostgreSQL database endpoint"
  value       = aws_db_instance.vehicle_database.endpoint
  sensitive   = true
}

output "s3_tracking_bucket" {
  description = "S3 bucket for tracking data storage"
  value       = aws_s3_bucket.tracking_data_storage.bucket
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alert_notification.arn
}

output "lambda_function_name" {
  description = "Name of the telemetry processor Lambda function"
  value       = aws_lambda_function.telemetry_processor.function_name
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail for audit logging"
  value       = aws_cloudtrail.fleet_audit_trail.name
}