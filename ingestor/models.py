from enum import Enum
from typing import Optional, Literal
from datetime import datetime
from pydantic import BaseModel, Field
from uuid import UUID


class TestStatus(str, Enum):
    "Allowed values for test case's status"
    PASS = "pass"
    FAIL = "fail"
    SKIP = "skip"

class TestCase(BaseModel):
    name: str = Field(
        ...,
        min_length=1,
        max_length=500,
        description="Name of the test case"
    )

    status: TestStatus = Field(
        ...,
        description="Status of the test case"
    )

    duration_ms: int = Field(
        ...,
        ge=0,
        description="Duration of the test case execution in milliseconds"
    )

    critical: bool = Field(
        ...,
        description="Indicates if the test case is critical"
    )

    error_message: Optional[str] = Field(
        default=None,
        max_length=1000,
        description="Error message if the test case failed"
    )

class TestRunRequest(BaseModel):
    """What CLIENTS send to POST /results/json — represents one complete test execution submission."""
    team: str = Field(
        ...,
        max_length=100,
        min_length=1,
        description="Name of the team sending test run data"
            
    )

    project: str = Field(
        ...,
        max_length=100,
        min_length=1,
        description="Name of the project associated with the test run"
    )

    commit_sha: str = Field(
        ...,
        min_length=40,
        max_length=40,
        pattern=r"^[a-f0-9]{40}$",
        description="Exactly 40 chars (git SHA length)"
    )
    branch: str = Field(
        ...,
        max_length=200,
        min_length=1,
        description="Name of the branch associated with the test run"
    )

    ci_run_id: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Unique identifier for the CI run"
    )

    timestamp: datetime = Field(
        ...,
        description="Timestamp of when the test run was executed"
        )

    tests: list[TestCase] = Field(
        ...,
        min_length=1,
        description="List of test cases included in the test run"
        )
    
class TestRunResponse(BaseModel):
    """What WE return to the client after we successfully accept a Test Run"""
    status: Literal["accepted"] = Field(
        ...,
        description="Literal value 'accepted'"
    )
    ingestion_id: UUID = Field(
        ...,
        description="Server-generated unique ID"
    )
    received_at: datetime = Field(
        ...,
        description="Server timestamp (when we got the request)"
    )
    test_count: int = Field(
        ...,
        ge=1,
        description="How many test cases were in the submission"

    )
    source_format: Literal["json", "junit_xml"] = Field(
        ...,
        description="Either 'json' or 'junit_xml'"
    )