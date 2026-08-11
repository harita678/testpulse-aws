"""
inject_results.py — simulates a team's CI pipeline posting test results
to the TestPulse ingestor. Sends an API key in the X-API-Key header.

Usage:
    export TESTPULSE_API_KEY="tp_..."
    python inject_results.py
"""

import os
import secrets
from datetime import datetime, timezone

import requests

INGESTOR_URL = "http://testpulse-alb-247920472.ca-central-1.elb.amazonaws.com/results/json"
API_KEY = os.environ.get("TESTPULSE_API_KEY")


def build_payload():
    return {
        "team": "payments-team",
        "project": "emb mod",
        "commit_sha": secrets.token_hex(20),
        "branch": "main",
        "ci_run_id": f"run-{secrets.token_hex(4)}",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "tests": [
            {"name": "test_login",    "status": "pass", "duration_ms": 120, "critical": True,  "error_message": None},
            {"name": "test_checkout", "status": "pass", "duration_ms": 340, "critical": True,  "error_message": "timeout waiting for gateway"},
            {"name": "test_logout",   "status": "pass", "duration_ms": 80,  "critical": False, "error_message": None},
        ],
    }


def main():
    if not API_KEY:
        print("ERROR: set the API key first:  export TESTPULSE_API_KEY='tp_...'")
        return

    payload = build_payload()
    print(f"Posting test run for {payload['team']} / {payload['project']} ...")

    response = requests.post(
        INGESTOR_URL,
        json=payload,
        headers={"X-API-Key": API_KEY},
        timeout=10,
    )

    if response.status_code == 202:
        print("SUCCESS — ingestor accepted the run:")
        print(response.json())
    else:
        print(f"FAILED — status {response.status_code}")
        print(response.text)


if __name__ == "__main__":
    main()