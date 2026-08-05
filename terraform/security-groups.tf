# ============================================================================
# security-groups.tf — Creating separate resources for 3 secutiy groups for 3 tier. WEB, APP, DB
# ============================================================================

#Web tier - Ingestor / ALB (Internet facing)
resource "aws_security_group" "web" {
  name        = "testpulse-web"
  description = "TestPulse web tier - Ingestor EC2 and future ALB"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "sg-testpulse-web"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }

}

#App tier - Lambda/workers
resource "aws_security_group" "app" {
  name        = "testpulse-app"
  description = "TestPulse app tier - Lambda Processor and future workers"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "sg-testpulse-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }

}

#DB tier - Lambda/workers
resource "aws_security_group" "db" {
  name        = "harita-rds-sg"
  description = "Created by RDS management console"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name        = "sg-testpulse-db"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }

}