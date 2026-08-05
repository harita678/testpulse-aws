#!/bin/bash

echo "TestPulse Cleanup"

BUCKET_NAME="harita-testpulse-raw-2026"
QUEUE_URL="https://sqs.ca-central-1.amazonaws.com/951125265513/harita-testpulse-ingestion-queue"

echo "Emptying S3 bucket"
aws s3 rm "s3://$BUCKET_NAME" --recursive

echo "Purging SQS queue"
aws sqs purge-queue --queue-url "$QUEUE_URL"

echo "Cleanup done"
