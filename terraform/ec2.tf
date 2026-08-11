# ============================================================================
# EC2.tf — EC2 for TestPulse
# ============================================================================


resource "aws_instance" "ingestor" {
  # Core Configuration
  ami                  = "ami-0d19d7a9bc91b3550"
  instance_type        = "t3.micro"
  key_name             = "my-first-ec2-key"
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  # Network Association
  subnet_id                   = aws_subnet.private_1d.id
  associate_public_ip_address = false #Explicitly no public IP. This is the line that makes the box truly private — even though a private subnet wouldn't auto-assign one, we're explicit.
  vpc_security_group_ids      = [aws_security_group.app.id]

  #User Data - it is available on EC2 instance
  user_data = templatefile("${path.module}/user-data-testpulse.sh.tftpl", {
    db_host     = var.DB_HOST
    db_port     = var.DB_PORT
    db_name     = var.DB_NAME
    db_username = var.DB_USERNAME
    db_secret_arn = aws_secretsmanager_secret.db_password.arn
    testpulse_api_key = var.TESTPULSE_API_KEY

  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 enforced
    http_put_response_hop_limit = 2          # containers can reach IMDS
  }

  user_data_replace_on_change = true

  tags = {
    Name        = "harita-testpulse-ingestor"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }

}