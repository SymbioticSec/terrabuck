output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis data stream"
  value       = aws_kinesis_stream.sensor_data.name
}

output "kinesis_stream_arn" {
  description = "ARN of the Kinesis data stream"
  value       = aws_kinesis_stream.sensor_data.arn
}

output "lambda_function_name" {
  description = "Name of the anomaly detection Lambda function"
  value       = aws_lambda_function.anomaly_detection.function_name
}

output "lambda_function_arn" {
  description = "ARN of the anomaly detection Lambda function"
  value       = aws_lambda_function.anomaly_detection.arn
}

output "timestream_database_name" {
  description = "Name of the TimeStream database"
  value       = aws_timestreamwrite_database.sensor_data.database_name
}

output "timestream_table_name" {
  description = "Name of the TimeStream table"
  value       = aws_timestreamwrite_table.sensor_readings.table_name
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.analytics_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
}

output "compliance_storage_bucket" {
  description = "Name of the compliance storage S3 bucket"
  value       = aws_s3_bucket.compliance_storage.bucket
}

output "cloudtrail_logs_bucket" {
  description = "Name of the CloudTrail logs S3 bucket"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "iot_thing_type_name" {
  description = "Name of the IoT thing type for sensors"
  value       = aws_iot_thing_type.sensor.name
}

output "iot_policy_name" {
  description = "Name of the IoT policy for sensors"
  value       = aws_iot_policy.sensor_policy.name
}