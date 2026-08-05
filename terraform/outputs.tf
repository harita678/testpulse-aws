# ============================================================================
# outputs.tf — Useful values to expose after apply
# ============================================================================

# S3 outputs
output "s3_bucket_name" {
  description = "Name of the TestPulse raw data s3 bucket"
  value       = aws_s3_bucket.raw.bucket
}

# S3 outputs
output "s3_bucket_arn" {
  description = "Name of the TestPulse raw data s3 bucket"
  value       = aws_s3_bucket.raw.arn
}

# SQS outputs
output "sqs_queue_url" {
  description = "URL of the ingestion SQS queue"
  value       = aws_sqs_queue.ingestion.url
}

output "sqs_queue_arn" {
  description = "ARN of the ingestion SQS queue"
  value       = aws_sqs_queue.ingestion.arn
}
