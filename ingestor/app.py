from dotenv import load_dotenv
load_dotenv()
from datetime import datetime, timezone

from uuid import uuid4
from http import HTTPStatus
import json

from fastapi import FastAPI, status, Header, HTTPException, Depends
import os
from models import TestRunRequest, TestRunResponse
from aws_clients import get_sqs_client, get_aws_config, get_s3_client


app = FastAPI(
    title="TestPulse Ingestor", 
    version="0.1.0", 
    description="Receives test results from CI pipelines"
    )

def verify_api_key(x_api_key: str = Header(None)):
    expected = os.environ.get("TESTPULSE_API_KEY")
    if not expected or x_api_key != expected:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")

@app.get("/health")
def health_check():
    return {
        "status": "healthy"
    }

@app.post("/results/json", status_code=status.HTTP_202_ACCEPTED, response_model=TestRunResponse, dependencies=[Depends(verify_api_key)])
def create_test_run(test_run: TestRunRequest):
    config = get_aws_config()
    s3_client = get_s3_client()
    sqs_client = get_sqs_client()
    new_id=uuid4()
    current_time=datetime.now(timezone.utc)
    test_count=len(test_run.tests)

    #Before returning the response we actually need to write/save raw payloas to s3  
    s3_key = f"raw/{test_run.team}/{current_time.strftime('%Y-%m-%d')}/{new_id}.json" #Creating s3 key as per pre defined pattern
    json_body = test_run.model_dump_json()
    s3_client.put_object(Bucket=config["BUCKET_NAME"], Key=s3_key, Body=json_body)
    
    #After writing to S3 we need to put the message in SQS
    #1. Creating SQS message
    sqs_message={
        "ingestion_id":str(new_id),
        "s3_bucket":config["BUCKET_NAME"],
        "s3_key":s3_key
    }
    
    #2. Converting Dict to JSON string
    sqs_message_body_string = json.dumps(sqs_message)
    
    #3. Call sqs_client.send_message(...) to publish to SQS
    sqs_client.send_message(QueueUrl=config["SQS_QUEUE_URL"], MessageBody=sqs_message_body_string)


    return TestRunResponse(
        status="accepted",
        ingestion_id=new_id,
        received_at=current_time,
        test_count=test_count,
        source_format="json")
    
    



