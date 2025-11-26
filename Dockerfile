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
    wget \
    nodejs \
    npm \
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

# Pre-download YOLOv8 model to avoid startup delay
RUN python -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"

# Copy frontend dependencies separately for better caching
COPY frontend/package*.json ./frontend/
RUN cd frontend && npm ci

# Copy frontend source and build optimized assets
COPY frontend ./frontend
RUN cd frontend && npm run build && mv dist /app/frontend_dist
RUN rm -rf frontend

# Copy application files
COPY server.py config.yaml start.sh ./

# Make startup script executable
RUN chmod +x start.sh

# Create directories
RUN mkdir -p logs results/jsonl results/summaries results/annotated_videos downloads

# Expose port
EXPOSE 8000

# Run server using startup script
# Railway will handle health checks via the /health endpoint
CMD ["./start.sh"]
