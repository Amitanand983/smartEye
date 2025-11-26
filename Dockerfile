# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install minimal system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install PyTorch CPU version first (saves ~4GB)
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu

# Install core dependencies
RUN pip install --no-cache-dir \
    fastapi>=0.104.0 \
    "uvicorn[standard]>=0.24.0" \
    pydantic>=2.5.0 \
    httpx>=0.25.0 \
    websockets>=12.0 \
    python-multipart>=0.0.6 \
    aiofiles>=23.2.0 \
    pyyaml>=6.0.1 \
    psutil>=5.9.0

# Install vision dependencies
RUN pip install --no-cache-dir \
    numpy>=1.24.0 \
    pillow>=10.0.0 \
    opencv-python-headless>=4.8.0

# Install YOLOv8 and yt-dlp
RUN pip install --no-cache-dir \
    ultralytics>=8.0.0 \
    yt-dlp>=2023.10.0

# Copy only necessary files
COPY server.py config.yaml ./

# Create directories
RUN mkdir -p logs results/jsonl results/summaries results/annotated_videos downloads

# Expose port
EXPOSE 8000

# Health check - increased start period to allow model download
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=5)" || exit 1

# Run server
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]

