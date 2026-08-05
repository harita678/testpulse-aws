# ============================================================================
# main.tf — Terraform foundation for TestPulse
# ============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
  #Below block Tells Terraform "stop storing state on the laptop; use that S3 bucket + native locking with use_lockfile"
  backend "s3" {
    bucket = "harita-testpulse-tfstate-2026"
    key    = "testpulse/terraform.tfstate"
    region = "ca-central-1"
    #dynamodb_table = "harita-testpulse-tflock" 
    use_lockfile = true
    encrypt      = true
  }
}

# Provider config

provider "aws" {
  region = var.region

}