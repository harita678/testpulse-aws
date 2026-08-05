# ============================================================================
# default-vpc-data.tf — I am using default vpc so I dont need to create the separate resource here; in this file we are just referencing it.
# ============================================================================

data "aws_vpc" "default" {
  id = "vpc-0195a8984f6090bc2"
}

data "aws_subnet" "public_1a" {
  id = "subnet-0239c5c7454b3ff67"
}

data "aws_subnet" "public_1b" {
  id = "subnet-09aded2e838ab3491"
}

data "aws_subnet" "public_1d" {
  id = "subnet-062db854eb6c2a5bd"
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]

  }
}