# ============================================================================
# cloudwatch.tf — Observability: log retention, metrics, alarms
# ============================================================================

resource "aws_cloudwatch_log_group" "lambda_processor" {
  name              = "/aws/lambda/harita-testpulse-processor"
  retention_in_days = 14

  tags = {
    Name        = "TestPulse Lambda Logs"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}
# --- Saved Logs Insights queries (version-controlled) ---

resource "aws_cloudwatch_query_definition" "lambda_performance" {
  name = "TestPulse/Lambda-Performance"

  log_group_names = [
    aws_cloudwatch_log_group.lambda_processor.name
  ]

  query_string = <<-QUERY
    filter @type = "REPORT"
    | stats avg(@duration) as avg_ms, max(@duration) as max_ms, pct(@duration, 95) as p95_ms
  QUERY
}

resource "aws_cloudwatch_query_definition" "lambda_invocations" {
  name = "TestPulse/Run-Count"

  log_group_names = [
    aws_cloudwatch_log_group.lambda_processor.name
  ]

  query_string = <<-QUERY
    fields @message
    | filter @message like /Ingestion ID/
    | parse @message "Ingestion ID: *" as ingestion_id
    | stats count(*) as total_runs
  QUERY
}
#=========================================================
# DLQ depth alarm
#========================================================= 
resource "aws_cloudwatch_metric_alarm" "dlq_not_empty" {
  alarm_name        = "TestPulse-DLQ-Has-Messages"
  alarm_description = "A message failed 3 times and landed in the DLQ. Investigate."

  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"
  dimensions = {
    QueueName = aws_sqs_queue.ingestion_dlq.name
  }

  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "TestPulse DLQ Alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}

#=========================================================
# Alarm for Lambda when it throws errors
#========================================================= 
resource "aws_cloudwatch_metric_alarm" "lambda_throws_error" {
  alarm_name        = "TestPulse-Lambda-Errors"
  alarm_description = "The Lambda processor is throwing errors. Check CloudWatch Logs"

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  dimensions = {
    FunctionName = aws_lambda_function.processor.function_name
  }

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "TestPulse Lambda Alarm"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}