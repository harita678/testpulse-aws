# ============================================================================
# rds.tf — RDS Instance on AWS
# ============================================================================


resource "aws_db_instance" "testpulse_db" {

  lifecycle {
    prevent_destroy = true
  }

  identifier        = "harita-testpulse-db-private"
  engine            = "postgres"
  engine_version    = "18.3"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.DB_NAME
  username = var.DB_USERNAME
  port     = var.DB_PORT
  password = var.DB_PASSWORD

  multi_az            = false
  publicly_accessible = false
  apply_immediately   = true

  vpc_security_group_ids = [aws_security_group.db.id]

  db_subnet_group_name = aws_db_subnet_group.private.name

  storage_encrypted = true

  skip_final_snapshot   = true
  copy_tags_to_snapshot = true
  max_allocated_storage = 1000

}

# Creating DB Subnet group which contains private subnets..as my RDS is in private subnet it should use privite subnet group
# Here i am just creating subnet group (which has private subnets) then in "aws_db_instance" resoucre we will refer it

resource "aws_db_subnet_group" "private" {
  name = "testpulse-db-private"

  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1b.id,
    aws_subnet.private_1d.id,
  ]

  tags = {
    Name        = "testpulse-db-private"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}