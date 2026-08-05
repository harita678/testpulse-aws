from pydantic import BaseModel
from typing import Optional, Literal
from uuid import UUID
from datetime import datetime



class TestCaseResponse(BaseModel):
    name: str
    status: str
    duration_ms: int
    critical: bool

class TestRunDetailsResponse(BaseModel):
    ingestion_id: UUID
    team: str
    project: str
    timestamp: datetime
    total: int
    passed: int
    failed: int
    test_cases: list[TestCaseResponse] 

class TestRunsResponse(BaseModel):
    ingestion_id: UUID
    team: str
    project: str
    timestamp: datetime
    total: int
    passed: int
    failed: int

class StatsResponse(BaseModel):
    team: str
    run_count: int
    total_tests: int
    total_passed: int
    total_failed: int