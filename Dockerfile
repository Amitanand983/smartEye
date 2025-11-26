# Use Python 3.11 slim image (smaller base)
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# Install minimal system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements
COPY requirements.txt .

# Install dependencies with size optimizations
# Install CPU-only torch to save ~4GB
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    torch torchvision --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir \
    fastapi==0.104.0 \
    uvicorn[standard]==0.24.0 \
    opencv-python-headless==4.8.0.76 \
    numpy==1.24.3 \
    pillow==10.0.0 \
    pydantic==2.5.0 \
    python-multipart==0.0.6 \
    aiofiles==23.2.1 \
    pyyaml==6.0.1 \
    psutil==5.9.5 \
    httpx==0.25.0 \
    websockets==12.0 \
    ultralytics==8.0.196 \
    yt-dlp==2023.10.13 && \
    pip cache purge

# Copy only necessary files
COPY server.py config.yaml ./

# Create directories
RUN mkdir -p logs results/jsonl results/summaries results/annotated_videos downloads

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=5)" || exit 1

# Run server
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]

