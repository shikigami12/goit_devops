output "bucket_name" {
  description = "Name of the S3 bucket created for Terraform state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket created for Terraform state"
  value       = aws_s3_bucket.tfstate.arn
}

output "bucket_url" {
  description = "S3 URL of the state bucket (s3://<name>)"
  value       = "s3://${aws_s3_bucket.tfstate.bucket}"
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  value       = aws_dynamodb_table.tflock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table used for state locking"
  value       = aws_dynamodb_table.tflock.arn
}
