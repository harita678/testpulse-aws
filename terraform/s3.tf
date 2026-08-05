# ============================================================================
# s3.tf — S3 buckets for TestPulse
# ============================================================================

resource "aws_s3_bucket" "raw" {
  bucket = var.s3_bucket_name
  tags = {
    Name        = "TestPulse raw data"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}