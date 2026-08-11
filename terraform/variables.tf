# ============================================================================
# variables.tf — Input variables for TestPulse infrastructure
# ============================================================================

variable "region" {
  description = "Region name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue for integration events"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket name"
  type        = string
}

variable "lambda_role_name" {
  description = "Name of the IAM Role that Lambda function will assume"
  type        = string
}

variable "ec2_role_name" {
  description = "Name of IAM Role that EC2 will assume"
  type        = string
}

variable "DB_HOST" {
  description = "RDS DB_HOST for Lambda DB Connection"
  type        = string

}
variable "DB_PORT" {
  description = "RDS port for Lambda DB Connection"
  type        = string

}
variable "DB_NAME" {
  description = "RDS database name for Lambda DB Connection"
  type        = string
}
variable "DB_USERNAME" {
  description = "RDS user name for Lambda DB Connection"
  type        = string

}

variable "DB_PASSWORD" {
  description = "RDS Master passwrod for Lambda DB Connection"
  type        = string
  sensitive   = true

}

variable "lambda_function_name" {
  description = "Name of the Testpulse Lambd processor function"
  type        = string
}

variable "alert_emails" {
  description = "Email addresses to receive TestPulse alerts"
  type        = set(string)
}
variable "TESTPULSE_API_KEY" {
  description = "API key that clients must send in the X-API-Key header to post results"
  type        = string
  sensitive   = true
}