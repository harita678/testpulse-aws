# ============================================================================
# event-source-mapping.tf — The Event Source Mapping is the "wire" connecting SQS to Lambda. 
# ============================================================================

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.ingestion.arn
  function_name    = aws_lambda_function.processor.arn
  batch_size       = 1
  enabled          = true


}