output "s3_bucket_name" {
  description = "Name of the S3 bucket for video storage"
  value       = aws_s3_bucket.corporate_training_video_streaming_platform_storage_primary.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.corporate_training_video_streaming_platform_cdn_distribution.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.corporate_training_video_streaming_platform_cdn_distribution.domain_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for video metadata"
  value       = aws_dynamodb_table.corporate_training_video_streaming_platform_database_metadata.name
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.corporate_training_video_streaming_platform_user_pool.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.corporate_training_video_streaming_platform_user_pool_client.id
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = aws_api_gateway_stage.corporate_training_video_streaming_platform_api_stage.invoke_url
}

output "lambda_function_name" {
  description = "Lambda function name for video processing"
  value       = aws_lambda_function.corporate_training_video_streaming_platform_processing_video.function_name
}