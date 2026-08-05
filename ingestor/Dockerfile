# Python 3.12 — MUST match the Lambda/prod runtime (this is the parity fix)
FROM python:3.12-slim

# Where the app lives inside the container or working directory inside the container, everything happens here
WORKDIR /app

# Install deps FIRST, before copying code (layer caching — explained below)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Now copy the application code
COPY . .

# Document the port the app listens on
EXPOSE 8000

# The command that runs when the container starts
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]