# ============================================================================
# sqs.tf — SQS Queue for TestPulse
# ============================================================================

resource "aws_sqs_queue" "ingestion" {
  name = var.sqs_queue_name

  tags = {
    Name        = "TestPulse Ingestion Queue"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
  lifecycle {
    ignore_changes = [
      max_message_size
    ]
  }
  redrive_policy = jsonencode(
    {
      deadLetterTargetArn = aws_sqs_queue.ingestion_dlq.arn
      maxReceiveCount     = 3
    }
  )

}

resource "aws_sqs_queue" "ingestion_dlq" {
  name = "harita-testpulse-ingestion-dlq"

  message_retention_seconds = 1209600
  tags = {
    Name        = "TestPulse Ingestion DLQ"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}
