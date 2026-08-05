# Test_app.py has tests for dashboard's endpoints
# mocking - mocking replaces what the function does, not whether it's called. The call is real; only the database work is faked. That's why we can assert on the call.
from fastapi.testclient import TestClient
from unittest.mock import patch
from app import app

client = TestClient(app)

def test_health_retunrs_healthy():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {
        "status":"healthy"
    }
@patch("app.get_all_runs")
def test_runs_returns_list(mock_get_all_runs):
    mock_get_all_runs.return_value = [
        {
         "ingestion_id": "11111111-1111-1111-1111-111111111111",
            "team": "payments",
            "project": "checkout-service",
            "timestamp": "2026-07-14T10:00:00Z",
            "total": 3,
            "passed": 2,
            "failed": 1,   
        },
        
        {
         "ingestion_id": "11111111-2222-3333-4444-555555555555",
            "team": "CMTR",
            "project": "checkout-service",
            "timestamp": "2026-07-14T10:00:00Z",
            "total": 3,
            "passed": 2,
            "failed": 1, 
        }
    ]
    response = client.get("/runs")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["team"] == "payments"
    mock_get_all_runs.assert_called_once()

@patch("app.get_run_by_id")
def test_run_details_returns_run_with_test_cases(mock_get_run_by_id):
    mock_get_run_by_id.return_value = {
        "ingestion_id": "11111111-1111-1111-1111-111111111111",
        "team": "payments",
        "project": "checkout-service",
        "timestamp": "2026-07-14T10:00:00Z",
        "total": 3,
        "passed": 2,
        "failed": 1,
        "test_cases": [
            {"name": "test_charge_card", "status": "pass", "duration_ms": 120, "critical": True},
            {"name": "test_timeout", "status": "fail", "duration_ms": 5000, "critical": True},
        ],
    }
    response = client.get("/runs/11111111-1111-1111-1111-111111111111")

    assert response.status_code == 200
    data = response.json()
    assert data["team"] == "payments"
    assert len(data["test_cases"]) == 2
    assert data["test_cases"][0]["name"] == "test_charge_card"

def test_run_detail_returns_404_for_malformed_id():
    response = client.get("/runs/123")

    assert response.status_code == 404
    assert response.json()["detail"] == "Run not found"

@patch("app.get_run_by_id")
def test_run_detail_returns_404_for_missing_run(mock_get_run_by_id):
    mock_get_run_by_id.return_value = None

    response = client.get("/runs/11111111-1111-1111-1111-111111111112")

    assert response.status_code == 404
    assert response.json()["detail"] == "Run not found"
    mock_get_run_by_id.assert_called_once() # Here my test is still going to db.get_run_by_id() but in that function instead of making db connection and then returning the data instead it returns data that we provided at line# 76

@patch("app.get_stats")
def test_stats_returns_aggregates(mock_get_stats):
    mock_get_stats.return_value = [
        {
            "team": "payments",
            "run_count": 1,
            "total_tests": 3,
            "total_passed": 2,
            "total_failed": 1,
        },
        {
            "team": "search",
            "run_count": 1,
            "total_tests": 2,
            "total_passed": 2,
            "total_failed": 0,
        },
    ]

    response = client.get("/stats")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["team"] == "payments"
    assert data[0]["total_failed"] == 1
    mock_get_stats.assert_called_once()