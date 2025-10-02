output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "content_storage_bucket" {
  description = "Name of the content storage bucket"
  value       = aws_s3_bucket.content_storage.id
}

output "processed_content_bucket" {
  description = "Name of the processed content bucket"
  value       = aws_s3_bucket.processed_content_storage.id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.user_database.endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "lambda_function_name" {
  description = "Name of the content processing Lambda function"
  value       = aws_lambda_function.content_processing.function_name
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.global_cdn.domain_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.backend_services.repository_url
}