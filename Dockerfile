# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables for faster builds
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies in one layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies with optimizations
# Install in order: lightweight packages first, then heavy ones
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir \
    pyyaml pydantic aiofiles python-multipart psutil httpx websockets && \
    pip install --no-cache-dir fastapi uvicorn[standard] && \
    pip install --no-cache-dir numpy pillow && \
    pip install --no-cache-dir opencv-python-headless && \
    pip install --no-cache-dir ultralytics && \
    pip install --no-cache-dir yt-dlp

# Copy only necessary application files
COPY server.py client.py config.yaml ./
COPY *.py ./

# Create necessary directories
RUN mkdir -p logs results/jsonl results/summaries results/annotated_videos downloads

# Expose port
EXPOSE 8000

# Simplified health check (remove requests dependency)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Run the application
CMD uvicorn server:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1
