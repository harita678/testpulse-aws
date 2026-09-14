# ============================================================================
# network.tf — Networking for the EKS cluster
#
# Layout:
#   Default VPC (already exists, not managed here)
#     ├── Public subnets  (already exist)  → internet gateway
#     │     └── NAT gateway lives here
#     └── Private subnets (created here)   → NAT gateway (outbound only)
#           └── EKS worker nodes live here
# ============================================================================


# ----------------------------------------------------------------------------
# 1. LOOKUPS — things that already exist
#
# "data" reads existing resources. Terraform does not own or destroy these.
# ----------------------------------------------------------------------------

# The account's default VPC. One per region, so no ID needed.
data "aws_vpc" "default" {
  default = true
}

# The availability zones in this region (ca-central-1a, 1b, 1d).
# Looked up rather than hardcoded, because AZ names differ per region.
data "aws_availability_zones" "available" {
  state = "available"
}

# The default VPC's public subnets — one per AZ, already routed to the
# internet gateway. Reused for the ALB and as the home of the NAT gateway.
#
# Note: aws_subnets (plural) returns a LIST. aws_subnet (singular) returns
# one and errors if the filter matches more than one.
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  # Each default VPC has exactly one default subnet per AZ.
  # This filter finds those and excludes anything else.
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}


# ----------------------------------------------------------------------------
# 2. PRIVATE SUBNETS — where the worker nodes run
#
# EKS requires subnets in at least two AZs. Three means losing one zone
# does not take out the cluster.
# ----------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count = 3

  vpc_id = data.aws_vpc.default.id

  # 172.31.48.0/20, 172.31.64.0/20, 172.31.80.0/20
  # Each /20 is 16 wide in the third octet, so they sit side by side.
  # Starts at 48 because the default VPC already uses 0, 16 and 32.
  cidr_block = "172.31.${48 + count.index * 16}.0/20"

  availability_zone = data.aws_availability_zones.available.names[count.index]

  # map_public_ip_on_launch defaults to false — instances here get no public IP.

  tags = {
    Name = "testpulse-eks-private-${count.index + 1}"

    # FUNCTIONAL, not decorative. The AWS Load Balancer Controller finds
    # subnets by this tag. Without it, an Ingress silently creates nothing.
    "kubernetes.io/role/internal-elb" = "1"
  }
}


# ----------------------------------------------------------------------------
# 3. NAT GATEWAY — outbound internet for the private subnets
#
# Worker nodes need to reach out to pull images from ECR, talk to the EKS
# control plane, and download packages. NAT allows traffic OUT only —
# nothing on the internet can start a connection inward.
#
# COST: ~$0.045/hour (~$32/month) plus data processing.
#       This is the largest line item. Destroy it when not in use.
# ----------------------------------------------------------------------------

# A static public IP for the NAT gateway.
resource "aws_eip" "nat" {
  domain = "vpc" # was "vpc = true" in older provider versions

  tags = {
    Name = "testpulse-eks-nat-eip"
  }
}

# The NAT gateway itself.
#
# It sits in a PUBLIC subnet even though it serves private ones — that is the
# whole mechanism. Private traffic goes to the NAT, and the NAT (being in a
# public subnet) can reach the internet gateway. Put it in a private subnet
# and it would have no route out itself.
#
# Production note: this is one NAT in one AZ — cheapest, but a single point of
# failure. Production would run one NAT per AZ.
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.aws_subnets.public.ids[0]

  tags = {
    Name = "testpulse-eks-nat"
  }
}


# ----------------------------------------------------------------------------
# 4. PRIVATE ROUTE TABLE — what makes these subnets "private"
#
# A subnet is public or private because of its route table, not because of a
# setting. Route 0.0.0.0/0 to an internet gateway and it is public. Route it
# to a NAT and it is private — outbound only.
#
# AWS adds an implicit local route (172.31.0.0/16 → local) automatically,
# which is why subnets can talk to each other without a rule here. Routing
# uses most-specific-match, so the local /16 beats this /0 for internal traffic.
# ----------------------------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id

  # Inline route block. Do not also create a separate aws_route pointing at
  # this table — an inline block is treated as the complete set of routes,
  # and the two would fight on every apply.
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "testpulse-eks-private-rt"
  }
}

# Creating a route table does nothing on its own. Association is what makes a
# subnet use it. One route table serves all three subnets — a subnet has
# exactly one route table, but a route table can serve many subnets.
resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


# ----------------------------------------------------------------------------
# 5. PUBLIC SUBNET TAGS
#
# The public subnets belong to the default VPC, so they are not managed here.
# But tags are additive: aws_ec2_tag manages a single tag on a resource
# Terraform does not own. It adds the tag on apply and removes it on destroy,
# leaving the subnet itself untouched.
#
# This tag tells the AWS Load Balancer Controller where to put
# internet-facing load balancers.
# ----------------------------------------------------------------------------

resource "aws_ec2_tag" "public_elb" {
  count = length(data.aws_subnets.public.ids)

  resource_id = data.aws_subnets.public.ids[count.index]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}


# ----------------------------------------------------------------------------
# OUTPUTS — consumed by eks.tf and nodes.tf
# ----------------------------------------------------------------------------

output "vpc_id" {
  description = "The default VPC the cluster runs in"
  value       = data.aws_vpc.default.id
}

output "private_subnet_ids" {
  description = "Private subnets for the EKS worker nodes"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnets for internet-facing load balancers"
  value       = data.aws_subnets.public.ids
}