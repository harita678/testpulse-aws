# ============================================================================
# vpc.tf — VPC Endpoints for connecting vpc to s3
# ============================================================================


#Lambda is in private subnet of VPC and we will use VPC Endpoint to reach s3 privately(not over the network to save the cost)

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = "vpc-0195a8984f6090bc2"         # your VPC ID
  service_name      = "com.amazonaws.ca-central-1.s3" # the S3 service name
  vpc_endpoint_type = "Gateway"                       # "Gateway"

  route_table_ids = ["rtb-0a6ee008b2ba557be",
  aws_route_table.private.id] # list with your route table ID, as we moved lambda to private subnet it is attached to private route table. VPC endpoints are connected to route table, so we need to connect it to private route table too!!

  tags = {
    Name        = "VPC Endpoint Connecting to S3" # e.g., "TestPulse S3 Endpoint"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "TestPulse"
  }
}