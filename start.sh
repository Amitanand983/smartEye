#!/bin/sh
# Startup script for Railway deployment
# This ensures PORT environment variable is properly handled

# Use Railway's PORT if set, otherwise default to 8000
PORT=${PORT:-8000}

echo "Starting server on port $PORT"
exec uvicorn server:app --host 0.0.0.0 --port $PORT --workers 1
