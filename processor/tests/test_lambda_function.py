import json
import os

os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_DEFAULT_REGION"] = "ca-central-1"

from moto import mock_aws
from unittest.mock import patch
from lambda_function import lambda_handler
import boto3

BUCKET_NAME = "test-testpulse-bucket"
OBJECT_KEY = "raw/team/date/file.json"

@patch('lambda_function.db')#adding @patch() to prevent real DB connection during this test. No new assertions added.
@mock_aws
def test_lambda_handler_processes_test_run(mock_db):
    s3_client = boto3.client("s3", region_name="ca-central-1")
    s3_client.create_bucket(
        Bucket=BUCKET_NAME, 
        CreateBucketConfiguration={"LocationConstraint": "ca-central-1"}
    )
    fake_test_data = {
       "ingestion_id": "fake-uuid-123",
        "team": "callmetoremind",
        "project": "backend-service",
        "commit_sha": "abc1234567890abcdef1234567890abcdef12345",
        "branch": "main",
        "ci_run_id": "ci-run-2026-06-22-001",
        "timestamp": "2026-06-22T10:30:00Z",
        "tests": [
            {"name": "testCreateReminder", "status": "pass", "duration_ms": 100, "critical": False},
            {"name": "testSendVerificationCode", "status": "pass", "duration_ms": 89, "critical": True},
            {"name": "testInvalidPhoneNumber", "status": "fail", "duration_ms": 50, "critical": True},
        ] 
    }

    s3_client.put_object(Bucket=BUCKET_NAME, 
                         Key=OBJECT_KEY,
                         Body=json.dumps(fake_test_data))
    
    fake_event = {
        "Records":[
            {
            "message_id": "msg_123",
            "body": json.dumps(
                {
                    "ingestion_id": "fake-uuid-123",
                    "s3_bucket": BUCKET_NAME,
                    "s3_key": OBJECT_KEY
                }
            )}]}
    result= lambda_handler(fake_event,None)

    assert result["statusCode"]==200

    assert result["body"]["team"]=="callmetoremind"
    assert result["body"]["ci_run_id"]=="ci-run-2026-06-22-001"
    assert result["body"]["total"]==3
    assert result["body"]["passed"]==2
    assert result["body"]["failed"]==1

@patch('lambda_function.db')
@mock_aws
def test_lambda_handler_calls_db_functions_in_order(mock_db):
    s3_client = boto3.client("s3", region_name="ca-central-1")
    s3_client.create_bucket(
        Bucket=BUCKET_NAME, 
        CreateBucketConfiguration={"LocationConstraint": "ca-central-1"}
    )
    fake_test_data = {
       "ingestion_id": "fake-uuid-123",
        "team": "callmetoremind",
        "project": "backend-service",
        "commit_sha": "abc1234567890abcdef1234567890abcdef12345",
        "branch": "main",
        "ci_run_id": "ci-run-2026-06-22-001",
        "timestamp": "2026-06-22T10:30:00Z",
        "tests": [
            {"name": "testCreateReminder", "status": "pass", "duration_ms": 100, "critical": False},
            {"name": "testSendVerificationCode", "status": "pass", "duration_ms": 89, "critical": True},
            {"name": "testInvalidPhoneNumber", "status": "fail", "duration_ms": 50, "critical": True},
        ] 
    }

    s3_client.put_object(Bucket=BUCKET_NAME, 
                         Key=OBJECT_KEY,
                         Body=json.dumps(fake_test_data))
    
    fake_event = {
        "Records":[
            {
            "message_id": "msg_123",
            "body": json.dumps(
                {
                    "ingestion_id": "fake-uuid-123",
                    "s3_bucket": BUCKET_NAME,
                    "s3_key": OBJECT_KEY
                }
            )}]}
    result= lambda_handler(fake_event,None)

    # Assert phase: we just want assert(test) if Lambda is making a call to db connection, insert_test_runs and insert_test_cases functions. we are tetsing lambda's job which is to make a call to db functions. we are not testing db's function which is to make rds connection and execute queries.
    mock_db.create_db_connection.assert_called_once()
    mock_db.insert_test_runs.assert_called_once()
    mock_db.insert_test_cases.assert_called_once()

    conn_mock = mock_db.create_db_connection.return_value

    conn_mock.commit.assert_called_once()
    conn_mock.close.assert_called_once()


