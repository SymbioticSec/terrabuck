output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.restaurant_pos_vpc.id
}

output "load_balancer_dns" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.pos_alb.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the application load balancer"
  value       = aws_lb.pos_alb.zone_id
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.inventory_database.endpoint
  sensitive   = true
}

output "database_port" {
  description = "RDS instance port"
  value       = aws_db_instance.inventory_database.port
}

output "cache_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = aws_elasticache_replication_group.cache_layer.primary_endpoint_address
}

output "transaction_storage_bucket" {
  description = "S3 bucket name for transaction storage"
  value       = aws_s3_bucket.transaction_storage.bucket
}

output "analytics_lambda_function_name" {
  description = "Name of the analytics Lambda function"
  value       = aws_lambda_function.analytics_processor.function_name
}

output "analytics_lambda_function_arn" {
  description = "ARN of the analytics Lambda function"
  value       = aws_lambda_function.analytics_processor.arn
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "data_subnet_ids" {
  description = "IDs of the data subnets"
  value       = [aws_subnet.data_subnet_1.id, aws_subnet.data_subnet_2.id]
}