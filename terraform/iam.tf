# ============================================================================
# iam.tf —  IAM Roles and Policies for TestPulse
# ============================================================================

#Lambda - IAM Role with trust policy

resource "aws_iam_role" "lambda" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "TestPulse Lambda Role"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}
# ====================================
# Attach AWS Managed policy
# ====================================

# 1. Attach AWSLambdaBasicExecutionRole policy

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 2. Attach AWSLambdaVPCAccessExecutionRole policy

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ====================================
# Attach AWS Inline policy
# ====================================

# 1. Attach TestPulseSQSandS3Access ploicy

resource "aws_iam_role_policy" "lambda_testpulse" {
  name = "TestPulseSQSandS3Access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadFromS3"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.raw.arn}/*"
      },
      {
        Sid    = "ReadFromSQS"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.ingestion.arn
      }
    ]
  })
}
# ── Let the Lambda role read the DB password secret ──
resource "aws_iam_role_policy" "lambda_secrets" {
  name = "testpulse-lambda-secrets-read"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadDBSecret"
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.db_password.arn
      }
    ]
  })
}
#-------------------------------------------
#EC2 - IAM Role with trust policy
#-------------------------------------------
resource "aws_iam_role" "ec2" {
  name = var.ec2_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "TestPulse EC2 Role"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}

# ======================================
# Attach AWS Managed policy on EC2 Role - As EC2 is in private subnet we need SSM to do ssh from the local computer. 
# =======================================
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}



# ====================================
# Attach AWS Inline policy on EC2 Role
# ====================================

# 1. Attach TestPulseEC2InlinePolicy ploicy

resource "aws_iam_role_policy" "ec2_inline" {
  name = "TestPulseEC2InlinePolicy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SendMessageToSQS"
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.ingestion.arn
      },
      {
        Sid    = "WriteToS3"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.raw.arn}/*"
      },
      {
        Sid    = "WriteCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"

        ]
        Resource = "arn:aws:logs:ca-central-1:951125265513:*"

      }
    ]
  })
}
# ── Let the EC2 role (dashboard) read the same secret ──
resource "aws_iam_role_policy" "ec2_secrets" {
  name = "testpulse-ec2-secrets-read"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadDBSecret"
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.db_password.arn
      }
    ]
  })
}
# ====================================
# Attach EC2 Instance profile
# ====================================

resource "aws_iam_instance_profile" "ec2" {
  name = var.ec2_role_name
  role = aws_iam_role.ec2.name
}