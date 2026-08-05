from dotenv import load_dotenv
import os
import psycopg2

load_dotenv() # reads .env, populates os.environ
# Reading cred from .env

db_host = os.environ["DB_HOST"]
db_name = os.environ["DB_NAME"]
db_username = os.environ["DB_USERNAME"]
db_password = os.environ["DB_PASSWORD"]
db_port = os.environ["DB_PORT"]

print("Connecting to RDS...")
conn = psycopg2.connect(
    host=db_host,
    port=db_port,
    database=db_name,
    user=db_username,
    password=db_password
)

# Reading all queries from schema.sql file
print("Connected. Reading schema...")
with open("schema.sql", "r", encoding="utf-8") as file:
    schema_sql = file.read()

# Execute schema_sql using cursor

try:
    cursor = conn.cursor()
    cursor.execute(schema_sql)
    conn.commit()
    print("Schema created successfully!")
except Exception as e:
    print(f"Error: {e}")
    conn.rollback()  # undo partial changes
finally:
    cursor.close()    # ALWAYS run, even on error
    conn.close()
