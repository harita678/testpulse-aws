#!/bin/bash

set -e # Exit on any error

# Step1: Create target group

aws elbv2 create-target-group \
  --name harita-testpulse-tg \
  --protocol HTTP \
  --port 8000 \
  --vpc-id vpc-0195a8984f6090bc2 \
  --target-type instance \
  --health-check-protocol HTTP \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3

# Step 2: Register the EC2 as a target in Target group
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:ca-central-1:951125265513:targetgroup/harita-testpulse-tg/7c7790cd8474ab0d \
  --targets Id=i-0102f7e914b91380c

# Step 3 Create ALB
aws elbv2 create-load-balancer \
  --name harita-testpulse-alb \
  --type application \
  --scheme internet-facing \
  --subnets subnet-062db854eb6c2a5bd subnet-09aded2e838ab3491 subnet-0239c5c7454b3ff67 \
  --security-groups sg-00168e19f0ed89a40 \
  --ip-address-type ipv4

# Step 4 We need Listener in ALB to listen to traffic and forward it to the target group
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:ca-central-1:951125265513:loadbalancer/app/harita-testpulse-alb/261d51aeb4bb8fe2 \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:ca-central-1:951125265513:targetgroup/harita-testpulse-tg/7c7790cd8474ab0d

# Step 5 we need to add port 80 to security group
aws ec2 authorize-security-group-ingress \
  --group-id sg-00168e19f0ed89a40 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
