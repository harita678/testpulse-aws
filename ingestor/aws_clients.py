import boto3
import os


def get_aws_config():
    return {
        "AWS_REGION":os.environ["AWS_REGION"],
        "BUCKET_NAME":os.environ["S3_BUCKET_NAME"],
        "SQS_QUEUE_URL":os.environ["SQS_QUEUE_URL"],
        
    }
def get_s3_client():
    return boto3.client('s3', region_name=os.environ["AWS_REGION"])

def get_sqs_client():
    return boto3.client('sqs', region_name=os.environ["AWS_REGION"])