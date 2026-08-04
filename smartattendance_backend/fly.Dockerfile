# Fly.io Dockerfile for SmartAttendance backend
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies for SQLite and psycopg2
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create data directory for SQLite database (persisted via Fly volume)
RUN mkdir -p /data

# Generate SECRET_KEY at build time if not provided
ENV SECRET_KEY="smartattendance-jwt-secret-change-in-production"
ENV DATABASE_URL="sqlite:////data/smartattendance.db"

# Expose port (Fly uses 8000 internally, routes 80/443 via fly.toml)
EXPOSE 8000

# Run with uvicorn
CMD ["uvicorn", "main:create_app", "--factory", "--host", "0.0.0.0", "--port", "8000"]
