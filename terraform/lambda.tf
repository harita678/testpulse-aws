# ============================================================================
# lambda.tf — lambda process function for Testpulse
# ============================================================================

resource "aws_lambda_function" "processor" {
  #Basic/ Mandatory confi
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  memory_size   = 256
  timeout       = 30

  # Code (the ZIP)
  filename         = "${path.module}/../processor/lambda-deployment.zip"
  source_code_hash = filebase64sha256("${path.module}/../processor/lambda-deployment.zip")

  # VPC config (nested block)
  vpc_config {
    subnet_ids = [
      aws_subnet.private_1a.id,
      aws_subnet.private_1b.id,
      aws_subnet.private_1d.id
    ]
    security_group_ids = ["sg-0f01497b00f9a0d26"]
  }
  # Environment variables (nested block)
  environment {
    variables = {
      DB_HOST       = var.DB_HOST
      DB_PORT       = var.DB_PORT
      DB_NAME       = var.DB_NAME
      DB_USERNAME   = var.DB_USERNAME
      DB_SECRET_ARN = aws_secretsmanager_secret.db_password.arn

      AWS_EMF_ENVIRONMENT = "Lambda"
    }
  }

  tags = {
    Name        = "TestPulse Lambda function"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }


}