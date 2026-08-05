# App.py is a weblayer for the Dashboard to display test runs and their test resulst for different teams. Teams can check their records here

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pathlib import Path
from db import get_all_runs, get_stats, get_run_by_id
from uuid import UUID
from models import TestCaseResponse, TestRunsResponse, StatsResponse,TestRunDetailsResponse

app = FastAPI(
    title="TestPulse Dashboard",
    description="Find your test run results here easily!!!"
)
@app.get("/", include_in_schema=False)
def dashboard_page():
    return FileResponse(Path(__file__).parent / "static" / "index.html")

@app.get("/health")
def health_check():
    return{
        "status": "healthy"
    }

@app.get("/runs", response_model=list[TestRunsResponse])
def all_runs():
    runs = get_all_runs()
    
    return runs
@app.get("/runs/{ingestion_id}", response_model=TestRunDetailsResponse)
def run_details(ingestion_id:str):
#Checking if it is valid uuid   
    try: 
        UUID(ingestion_id)
    except ValueError:
        raise HTTPException(status_code=404, detail="Run not found")
    run = get_run_by_id(ingestion_id)
    if run is None:
        raise HTTPException(status_code=404, detail="Run not found")
    return run

@app.get("/stats", response_model=list[StatsResponse])
def stats():
    return get_stats()



