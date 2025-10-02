output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.smart_parking_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.parking_database.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.parking_database.port
}

output "lambda_sensor_processing_arn" {
  description = "ARN of the sensor data processing Lambda function"
  value       = aws_lambda_function.sensor_data_processing.arn
}

output "lambda_payment_processing_arn" {
  description = "ARN of the payment processing Lambda function"
  value       = aws_lambda_function.payment_processing.arn
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.citizen_mobile_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.api_stage_name}"
}

output "admin_dashboard_bucket" {
  description = "S3 bucket name for admin dashboard"
  value       = aws_s3_bucket.admin_dashboard.bucket
}

output "cloudfront_distribution_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.admin_dashboard_cdn.domain_name
}

output "iot_thing_type_name" {
  description = "IoT Thing Type name for parking sensors"
  value       = aws_iot_thing_type.parking_sensor.name
}

output "cloudtrail_name" {
  description = "CloudTrail name for audit logging"
  value       = aws_cloudtrail.parking_system_audit.name
}