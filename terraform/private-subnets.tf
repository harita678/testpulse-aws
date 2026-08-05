# ============================================================================
# private-subnets.tf — Private subnets for the app + db tiers
# One private subnet per AZ (mirrors the existing public subnets). No public IP on launch.
# These have NO route to the internet gateway — that's what makes them private.
# ============================================================================

resource "aws_subnet" "private_1a" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.48.0/20"
  availability_zone = "ca-central-1a"

  tags = {
    Name        = "testpulse-private-1a"
    Tier        = "private"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }

}
resource "aws_subnet" "private_1b" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.64.0/20"
  availability_zone = "ca-central-1b"

  tags = {
    Name        = "testpulse-private-1b"
    Tier        = "private"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}

resource "aws_subnet" "private_1d" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.80.0/20"
  availability_zone = "ca-central-1d"

  tags = {
    Name        = "testpulse-private-1d"
    Tier        = "private"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}

# ── Private route table — deliberately NO internet gateway route ──

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id
  tags = {
    Name        = "testpulse-private-rt"
    Tier        = "private"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}

# ── Associate each private subnet with the private route table ──

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1d" {
  subnet_id      = aws_subnet.private_1d.id
  route_table_id = aws_route_table.private.id
}