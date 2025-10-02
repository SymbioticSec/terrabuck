output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.tickets.endpoint
  sensitive   = true
}

output "knowledge_base_bucket" {
  description = "S3 bucket name for knowledge base"
  value       = aws_s3_bucket.knowledge_base.bucket
}

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_deployment.main.invoke_url
}

output "lambda_function_names" {
  description = "Names of Lambda functions"
  value = [
    aws_lambda_function.ai_classifier.function_name,
    aws_lambda_function.sentiment_analysis.function_name
  ]
}

output "web_instance_ids" {
  description = "IDs of web server instances"
  value       = aws_instance.web[*].id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}