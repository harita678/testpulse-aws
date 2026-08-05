
import psycopg2
from dotenv import load_dotenv
from psycopg2.extras import RealDictCursor
import os
import json
import boto3

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


load_dotenv()  # reads .env, populates os.environ
#Open a connection to database (in Mac/local it will make a connectiong to Docker Postgress and on EC2 it will make a connection RDS)


def create_db_connection():
    
    #Reading cred from .env
    db_host = os.environ["DB_HOST"]
    db_name = os.environ["DB_NAME"]
    db_username = os.environ["DB_USERNAME"]
    db_password = get_db_password()
    db_port = os.environ["DB_PORT"]

    # Creating connection
    conn = psycopg2.connect(
          host=db_host,
        port=db_port,
        database=db_name,
        user=db_username,
        password=db_password
    )
    return conn

def get_all_runs():
    conn = create_db_connection()
    try:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute(
            "SELECT * FROM test_runs ORDER BY timestamp DESC"
        )
        rows = cursor.fetchall()
        cursor.close()
        return rows
    finally: 
        conn.close()

def get_run_by_id(ingestion_id):
    conn = create_db_connection()
    try:
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        # The run itself
        cursor.execute(
            "SELECT * FROM test_runs WHERE ingestion_id = %s",
            (ingestion_id,)
        )
        run = cursor.fetchone()

        if run is None:
            cursor.close()
            return None

        # Its test cases
        cursor.execute(
            "SELECT * FROM test_cases WHERE run_id = %s ORDER BY name",
            (ingestion_id,)
        )
        run["test_cases"] = cursor.fetchall()

        cursor.close()
        return run
    finally:
        conn.close()

def get_stats():
    conn = create_db_connection()
    try:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute("""
                SELECT team,
                       COUNT(*) as run_count,
                       SUM(total) as total_tests,
                       SUM(passed) as total_passed,
                       SUM(failed) AS total_failed
                FROM test_runs
                GROUP BY team
                ORDER BY team
                       """)
        rows = cursor.fetchall()
        cursor.close()
        return rows
    finally:
        conn.close()

# without the block below, create_db_connection() is never called → nothing happens
if __name__ == "__main__":
    stats = get_stats()
    for s in stats:
        print(f"{s['team']}: {s['run_count']} runs, "
              f"{s['total_passed']}/{s['total_tests']} passed")