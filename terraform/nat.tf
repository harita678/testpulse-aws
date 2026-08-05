# ============================================================================
# nat.tf — NAT gateway: outbound-only internet for private subnets
# Lives in a PUBLIC subnet (needs internet itself), serves the private subnets.
# ============================================================================

# Elastic IP — the fixed public address the NAT presents to the internet
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "testpulse-nat-eip"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}

# The NAT gateway — placed in an existing PUBLIC subnet (referenced)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.aws_subnet.public_1a.id

  tags = {
    Name        = "testpulse-nat"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}

# The route that gives private subnets their way out (0.0.0.0/0 → NAT)
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}