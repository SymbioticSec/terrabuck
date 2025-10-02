output "primary_backup_bucket_name" {
  description = "Name of the primary backup S3 bucket"
  value       = aws_s3_bucket.primary_backup_storage.bucket
}

output "primary_backup_bucket_arn" {
  description = "ARN of the primary backup S3 bucket"
  value       = aws_s3_bucket.primary_backup_storage.arn
}

output "disaster_recovery_bucket_name" {
  description = "Name of the disaster recovery S3 bucket"
  value       = aws_s3_bucket.disaster_recovery_storage.bucket
}

output "backup_gateway_instance_id" {
  description = "Instance ID of the backup gateway EC2 instance"
  value       = aws_instance.backup_gateway.id
}

output "backup_gateway_public_ip" {
  description = "Public IP address of the backup gateway"
  value       = aws_instance.backup_gateway.public_ip
}

output "backup_metadata_db_endpoint" {
  description = "RDS instance endpoint for backup metadata database"
  value       = aws_db_instance.backup_metadata_db.endpoint
  sensitive   = true
}

output "backup_orchestration_lambda_arn" {
  description = "ARN of the backup orchestration Lambda function"
  value       = aws_lambda_function.backup_orchestration.arn
}

output "vpc_id" {
  description = "ID of the backup system VPC"
  value       = aws_vpc.corporate_backup_vpc.id
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail for backup monitoring"
  value       = aws_cloudtrail.backup_monitoring.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for backup operations"
  value       = aws_cloudwatch_log_group.backup_logs.name
}