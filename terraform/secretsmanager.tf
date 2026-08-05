# The secret — the container. Named, but empty so far.
resource "aws_secretsmanager_secret" "db_password" {
  name        = "testpulse/db-password"
  description = "RDS master password for TestPulse dashboard + processor"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}

# The value that goes inside it.
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.DB_PASSWORD
}