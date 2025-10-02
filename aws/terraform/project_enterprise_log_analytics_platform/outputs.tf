output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.enterprise_log_analytics_vpc.id
}

output "api_gateway_url" {
  description = "URL of the API Gateway for log ingestion"
  value       = "${aws_api_gateway_deployment.log_ingestion_deployment.invoke_url}/logs"
}

output "lambda_function_name" {
  description = "Name of the log processing Lambda function"
  value       = aws_lambda_function.log_processing_pipeline.function_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for processed logs"
  value       = aws_s3_bucket.processed_logs_storage.bucket
}

output "elasticsearch_endpoint" {
  description = "Endpoint of the Elasticsearch domain"
  value       = aws_elasticsearch_domain.log_search_database.endpoint
}

output "elasticsearch_kibana_endpoint" {
  description = "Kibana endpoint for Elasticsearch domain"
  value       = aws_elasticsearch_domain.log_search_database.kibana_endpoint
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alert_notification_system.arn
}

output "dashboard_instance_id" {
  description = "ID of the dashboard EC2 instance"
  value       = aws_instance.log_analytics_dashboard.id
}

output "dashboard_private_ip" {
  description = "Private IP of the dashboard instance"
  value       = aws_instance.log_analytics_dashboard.private_ip
}