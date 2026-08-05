"""
TestPulse Lambda Processor

Triggered by SQS when a new test result message arrives. Fetches the raw test
data from S3, computes pass/fail summary, and (Phase 3) will persist to RDS.

Architecture: Ingestor → S3 + SQS → Lambda (this) → RDS
"""

import json
import boto3
import db
from aws_embedded_metrics import metric_scope
# ---------------------------------------------------------------------------
# Lambda handler — entry point AWS invokes when SQS has a message
# ---------------------------------------------------------------------------
def lambda_handler(event, context):
    """
    AWS Lambda entry point.
    
    Args:
        event: dict from AWS containing SQS records (see SQS event structure)
        context: AWS runtime metadata (function name, request ID, etc.)
    
    Returns:
        dict with statusCode and body — visible in CloudWatch logs
    """
    print("Lambda function invoked!")
    print(f"event received {event}")

    # SQS sends messages in event['Records'] (a list).
    # For now we process the first one. Multi-message handling comes later.
    json_body = event["Records"][0]["body"]
    
    # The 'body' is a JSON STRING — must parse to get the pointer dict.
    # This dict was created by the Ingestor when it published to SQS.
    body = json.loads(json_body)
    
    # Extract the S3 location of the actual test data
    # (Pointer pattern: SQS holds the pointer, S3 holds the payload)
    ingestion_id = body["ingestion_id"]
    bucket_name = body["s3_bucket"]
    object_key = body["s3_key"]

    print(f"Ingestion ID: {ingestion_id}")
    print(f"Bucket name: {bucket_name}")
    print(f"Object Key: {object_key}")

    # Fetch the actual test data from S3
    test_data = fetch_from_s3(bucket_name, object_key)
    test_data["ingestion_id"] = ingestion_id
    # Compute pass/fail summary
    summary = summarize_tests(test_data)

    # Creating db connection from db.py
    conn = None
    try:
        conn = db.create_db_connection()
        db.insert_test_runs(conn, test_data, summary)
        db.insert_test_cases(conn, test_data)
        conn.commit()
        emit_metrics(summary)
    except Exception as e:
        print(f"Database error: {e}")
        if conn:
            conn.rollback()  # undo any partial inserts
        raise  # let Lambda know it failed → SQS retry
    finally:
        if conn:
            conn.close()  # always close

    
    # Return success — AWS will mark the SQS message as processed
    # and remove it from the queue
    return {"statusCode": 200, "body": summary}


# ---------------------------------------------------------------------------
# S3 helper — fetches raw test data given a bucket + key
# ---------------------------------------------------------------------------
def fetch_from_s3(bucket_name, object_key):
    """
    Read a JSON object from S3 and return it as a Python dict.
    
    Args:
        bucket_name: S3 bucket name
        object_key: S3 object key (path within bucket)
    
    Returns:
        dict — the parsed JSON test result payload
    """
    # Lazy client creation — created inside function, not at module level.
    # This makes the code testable (moto can mock here) and avoids issues
    # with module-import-time AWS calls.
    s3_client = boto3.client('s3', region_name='ca-central-1') 

    # GET the object from S3
    response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
    
    # Read raw bytes from response, then decode to UTF-8 string,
    # then parse the JSON string into a Python dict
    json_body = response['Body'].read().decode('utf-8')
    parsed_data = json.loads(json_body)
    
    return parsed_data


# ---------------------------------------------------------------------------
# Summarizer — computes pass/fail counts from a test result payload
# ---------------------------------------------------------------------------
def summarize_tests(test_data):
    """
    Compute pass/fail summary statistics for a single test run.
    
    Args:
        test_data: dict matching TestRunRequest schema (team, ci_run_id, tests[])
    
    Returns:
        dict with team, ci_run_id, total, passed, failed counts
    """
    # Initialize counters
    total_pass = 0
    total_fail = 0
    total_tests = 0
    
    # Iterate over each test case in the payload
    for test in test_data["tests"]:
        total_tests += 1
        
        # Classify by status. Note: "skipped" and "error" currently fall
        # into total_fail. TODO: handle them separately when we write to RDS.
        if test["status"] == "pass":
            total_pass += 1
        else:
            total_fail += 1

    # Build the summary dict OUTSIDE the loop — single record, not snapshots
    test_record = {
        "team": test_data["team"],
        "ci_run_id": test_data["ci_run_id"],
        "project": test_data["project"],
        "total": total_tests,
        "passed": total_pass,
        "failed": total_fail,
    }

    return test_record

#this is EMF function.. it will create metrics in cloudwatch. 
#Namespace is a folder
#dimensions: how you filter and group your metrics
#put_metrics: actual metrics that we are creating, pass,failed, total
@metric_scope
def emit_metrics(test_summary, metrics):
    metrics.set_namespace("TestPulse")
    metrics.set_dimensions({"team": test_summary["team"], "project": test_summary["project"]})
    metrics.put_metric("TestsPassed", test_summary["passed"], "Count")
    metrics.put_metric("TestsFailed", test_summary["failed"], "Count")
    metrics.put_metric("TestsTotal", test_summary["total"], "Count")



