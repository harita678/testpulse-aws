#============================================
# Cloud Watch Dashboard; dashboard was created from the console, exported the json and going to use that json here in tf file. then we will use import
#============================================

resource "aws_cloudwatch_dashboard" "testpulse" {
  dashboard_name = "TestPulse"
  dashboard_body = file("${path.module}/dashboard.json")
}
