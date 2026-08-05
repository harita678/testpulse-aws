# ============================================================================
# sns.tf — Alerting topic for CloudWatch alarms
# ============================================================================

resource "aws_sns_topic" "alerts" {
  name = "harita-testpulse-alerts"

  tags = {
    Name        = "TestPulse Alerts"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  for_each = var.alert_emails

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value
}