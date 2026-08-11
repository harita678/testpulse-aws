import json

import boto3
import pytest
from fastapi.testclient import TestClient
from moto import mock_aws

from app import app

client = TestClient(app)
AUTH_HEADER = {"X-API-Key": "test-key-123"}

@pytest.fixture
def aws_env(monkeypatch):
    """Fake AWS credentials + app config, undone automatically after each test.

    The credentials are a safety net: if moto ever failed to intercept a call,
    boto3 would be holding garbage and AWS would reject it rather than doing
    something real.
    """
    env = {
        "AWS_ACCESS_KEY_ID": "testing",
        "AWS_SECRET_ACCESS_KEY": "testing",
        "AWS_DEFAULT_REGION": "ca-central-1",
        "AWS_REGION": "ca-central-1",
        "S3_BUCKET_NAME": "test-bucket",
        "TESTPULSE_API_KEY": "test-key-123"
        
    }
    for key, value in env.items():
        monkeypatch.setenv(key, value)
    return env


def test_health_return_healthy():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


@mock_aws
def test_post_results_json_returns_202_on_valid_payload(aws_env, monkeypatch):
    s3_client = boto3.client("s3", region_name=aws_env["AWS_REGION"])
    s3_client.create_bucket(
        Bucket=aws_env["S3_BUCKET_NAME"],
        CreateBucketConfiguration={"LocationConstraint": aws_env["AWS_REGION"]},
    )

    sqs_client = boto3.client("sqs", region_name=aws_env["AWS_REGION"])
    queue = sqs_client.create_queue(QueueName="test-queue")
    # moto generates the queue URL (including its own account id), so take
    # whatever it produced rather than hardcoding one.
    monkeypatch.setenv("SQS_QUEUE_URL", queue["QueueUrl"])

    payload = {
        "team": "callmetoremind",
        "project": "backend-service",
        "commit_sha": "abc1234567890abcdef1234567890abcdef12345",
        "branch": "main",
        "ci_run_id": "ci-run-2026-06-17-001",
        "timestamp": "2026-06-17T14:30:00Z",
        "tests": [
            {
                "name": "testCreateReminder",
                "status": "pass",
                "duration_ms": 142,
                "critical": False,
            }
        ],
    }

    response = client.post("/results/json", json=payload, headers=AUTH_HEADER)

    assert response.status_code == 202
    data = response.json()
    assert data["status"] == "accepted"
    assert data["source_format"] == "json"
    assert data["test_count"] == 1
    assert "ingestion_id" in data  # exists, but value is a random UUID
    assert "received_at" in data  # exists, but value is the current time

    # The payload actually landed in S3
    objects = s3_client.list_objects_v2(Bucket=aws_env["S3_BUCKET_NAME"])
    assert objects["KeyCount"] == 1
    key = objects["Contents"][0]["Key"]
    assert key.startswith("raw/callmetoremind/")

    # ...and a pointer to it was published to SQS
    messages = sqs_client.receive_message(QueueUrl=queue["QueueUrl"])
    body = json.loads(messages["Messages"][0]["Body"])
    assert body["s3_bucket"] == aws_env["S3_BUCKET_NAME"]
    assert body["s3_key"] == key
    assert body["ingestion_id"] == data["ingestion_id"]


@mock_aws
def test_post_results_json_returns_422_when_team_missing(aws_env):
    # No bucket or queue set up: validation rejects the payload before the
    # endpoint body runs, so nothing should reach S3 or SQS.
    payload = {
        "project": "backend-service",
        "commit_sha": "abc1234567890abcdef1234567890abcdef12345",
        "branch": "main",
        "ci_run_id": "ci-run-2026-06-17-001",
        "timestamp": "2026-06-17T14:30:00Z",
        "tests": [
            {
                "name": "testCreateReminder",
                "status": "pass",
                "duration_ms": 142,
                "critical": False,
            }
        ],
    }


    response = client.post("/results/json", json=payload, headers=AUTH_HEADER)

    assert response.status_code == 422


def test_post_results_json_returns_401_when_key_missing(aws_env):
    # No API key header → auth rejects before the payload is even looked at.
    # Payload is irrelevant here; we send an empty body on purpose.

    response = client.post("/results/json", json={})
    
    assert response.status_code == 401

def test_post_results_json_returns_401_when_key_invalid(aws_env):
# Wrong API key → auth rejects before the payload is looked at.
    response = client.post("/results/json", json={}, headers={"X-API-Key": "wrong-key"})
    
    assert response.status_code == 401