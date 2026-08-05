#!/bin/bash
set -e # exit immediately if any command failes

echo "=================================="
echo "        TestPulse Start"
echo "=================================="

cd ~/aws-lab/05-testpulse/ingestor

source venv/bin/activate

echo "Starting the uvicorn server"
uvicorn app:app --reload --port 8000
echo "Press Ctrl+C to stop"

