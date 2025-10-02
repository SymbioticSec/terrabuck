output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "document_storage_bucket" {
  description = "Name of the document storage S3 bucket"
  value       = aws_s3_bucket.document_storage.bucket
}

output "elasticsearch_endpoint" {
  description = "Elasticsearch domain endpoint"
  value       = aws_elasticsearch_domain.search_cluster.endpoint
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.user_database.endpoint
  sensitive   = true
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "lambda_function_name" {
  description = "Name of the document processor Lambda function"
  value       = aws_lambda_function.document_processor.function_name
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail"
  value       = aws_cloudtrail.main.name
}