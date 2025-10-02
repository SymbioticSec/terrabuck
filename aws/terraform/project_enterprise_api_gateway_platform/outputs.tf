output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = aws_api_gateway_deployment.main.invoke_url
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.main.id
}

output "lambda_authorizer_arn" {
  description = "ARN of the Lambda authorizer function"
  value       = aws_lambda_function.authorizer.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB tokens table"
  value       = aws_dynamodb_table.tokens.name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for API documentation"
  value       = aws_s3_bucket.api_docs.id
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.api_docs.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.api_docs.domain_name
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.api_keys.arn
}

output "root_access_key_id" {
  description = "Access key ID for root user"
  value       = aws_iam_access_key.root_access.id
  sensitive   = true
}

output "root_secret_access_key" {
  description = "Secret access key for root user"
  value       = aws_iam_access_key.root_access.secret
  sensitive   = true
}