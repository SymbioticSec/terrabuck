output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.hipaa_vpc.id
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.hipaa_alb.dns_name
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.hipaa_database.endpoint
  sensitive   = true
}

output "file_storage_bucket" {
  description = "S3 bucket name for file storage"
  value       = aws_s3_bucket.file_storage.bucket
}

output "backup_storage_bucket" {
  description = "S3 bucket name for backup storage"
  value       = aws_s3_bucket.backup_storage.bucket
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.hipaa_audit_logs.name
}

output "web_server_1_id" {
  description = "ID of web server 1"
  value       = aws_instance.web_server_1.id
}

output "web_server_2_id" {
  description = "ID of web server 2"
  value       = aws_instance.web_server_2.id
}

output "cloudtrail_name" {
  description = "CloudTrail name"
  value       = aws_cloudtrail.hipaa_audit_trail.name
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "private_app_subnet_ids" {
  description = "IDs of private app subnets"
  value       = [aws_subnet.private_app_subnet_1.id, aws_subnet.private_app_subnet_2.id]
}

output "private_data_subnet_ids" {
  description = "IDs of private data subnets"
  value       = [aws_subnet.private_data_subnet_1.id, aws_subnet.private_data_subnet_2.id]
}