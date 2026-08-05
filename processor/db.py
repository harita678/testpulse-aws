from dotenv import load_dotenv
import os
import psycopg2
import json
import boto3

#local it will read cred from .env on cloud it will will read password from secret manager

def get_db_password():
    """
    Local dev: DB_PASSWORD is in .env → use it directly.
    Cloud: DB_PASSWORD is absent → fetch from Secrets Manager using DB_SECRET_ARN.
    """
    # Local: env var present wins (no AWS call)
    pwd = os.environ.get("DB_PASSWORD")

    if pwd:
        return pwd
    # Cloud: fetch from Secrets Manager
    secret_arn = os.environ["DB_SECRET_ARN"]
    client=boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_arn)
    return response["SecretString"]

# Open a connection to RDS using credentials from .env
def create_db_connection():
    load_dotenv()  # reads .env, populates os.environ
    
    # Reading cred from .env
    db_host = os.environ["DB_HOST"]
    db_name = os.environ["DB_NAME"]
    db_username = os.environ["DB_USERNAME"]
    db_password = get_db_password()
    db_port = os.environ["DB_PORT"]
    
    # Creating connection
    print("Connecting to RDS...")
    conn = psycopg2.connect(
        host=db_host,
        port=db_port,
        database=db_name,
        user=db_username,
        password=db_password
    )
    return conn


# Insert ONE row into test_runs table (caller controls commit/close)
def insert_test_runs(conn, test_data: dict, test_summary: dict):
    cursor = conn.cursor()
    
    # Parameterized query to prevent SQL injection
    insert_test_run_query = "INSERT INTO test_runs (ingestion_id, team, project, commit_sha, branch, ci_run_id, timestamp, total, passed, failed) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);"
    
    # Run the insert with values pulled from test_data + test_summary
    cursor.execute(insert_test_run_query, (
        test_data["ingestion_id"],
        test_data["team"],
        test_data["project"],
        test_data["commit_sha"],
        test_data["branch"],
        test_data["ci_run_id"],
        test_data["timestamp"],
        test_summary["total"],
        test_summary["passed"],
        test_summary["failed"]
    ))
    
    cursor.close()


# Insert MULTIPLE rows into test_cases — one per test in the run
def insert_test_cases(conn, test_data):
    cursor = conn.cursor()
    value_list = []
    
    # Parameterized query (id is BIGSERIAL — auto-generated, skip it)
    insert_test_cases_query = "INSERT INTO test_cases (run_id, name, status, duration_ms, critical) VALUES (%s,%s,%s,%s,%s);"
    
    # Build list of tuples — one tuple per test case
    for test in test_data["tests"]:
        test_case = (
            test_data["ingestion_id"],
            test["name"],
            test["status"],
            test["duration_ms"],
            test["critical"]
        )
        value_list.append(test_case)
    
    # executemany runs the same query for each tuple in value_list
    cursor.executemany(insert_test_cases_query, value_list)
    
    cursor.close()